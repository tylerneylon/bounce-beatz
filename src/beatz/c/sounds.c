// beatz/c/sounds.c
//
// The capitalization style in this file is a tiny bit inconsistent because
// Apple uses CamelCase while my usual C and Lua style is to use underscores. I
// decided to use underscores everywhere except when referring directly to
// Apple-defined symbols.
//
// I also use some CamelCase elements when referring to type names; this is
// consistent with the rest of my personal preferred style.
//
// I'm avoiding this being an Objective-C file, but for future ference, here is
// how I can get more specific error information out of an OSStatus code:
//
//
//  NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
//                                       code:status
//                                   userInfo:nil];
//  NSLog(@"The error is %@", error);
//
// A useful reference for some of the Apple API used can be found by searching
// Apple docs for "Audio Queue Services Programming Guide."
//

#include "sounds.h"

#include "luajit/lauxlib.h"

#import <AudioToolbox/AudioToolbox.h>


// This is the Lua registry key for the sounds metatable.
#define sounds_mt "sounds_mt"


///////////////////////////////////////////////////////////////////////////////
// Internal globals and types.
///////////////////////////////////////////////////////////////////////////////

static int next_index = 1;

typedef struct {
  AudioQueueRef               queue;
  char *                      bytes;
  size_t                      num_bytes;
  char *                      cursor;
  int                         index;  // Index in the sounds_mt.playing table.
  int                         is_running;
  AudioStreamBasicDescription audio_desc;
  int                         do_stop;
  int                         num_to_skip;  // Number of buffers we'll skip.
} Sound;


///////////////////////////////////////////////////////////////////////////////
// Internal function declarations.
///////////////////////////////////////////////////////////////////////////////

static void setup_queue_for_sound(lua_State *L, Sound *sound);

void running_status_changed (void *user_data, AudioQueueRef queue,
                             AudioQueuePropertyID property);
void sound_play_callback    (void *user_data, AudioQueueRef queue,
                             AudioQueueBufferRef buffer);

static int delete_sound (lua_State* L);
static int play_sound   (lua_State *L);
static int stop_sound   (lua_State *L);
static int update       (lua_State *L);


///////////////////////////////////////////////////////////////////////////////
// Internal utility functions.
///////////////////////////////////////////////////////////////////////////////


// This assumes lua_State *L is in scope, which I consider good practice anyway.
#define jump_out_if_bad(status, fmt, ...) \
        if (status) { luaL_error(L, fmt, ##__VA_ARGS__); }

#define warn_if_bad(status, fmt, ...) \
        if (status) { printf("Warning: " fmt, ##__VA_ARGS__); }

// For debugging.
static void print_stack_types(lua_State *L) {
  printf("Stack types: [");
  int n = lua_gettop(L);
  for (int i = 1; i <= n; ++i) {
    printf(i == 1 ? "" : ", ");
    int tp = lua_type(L, i);
    const char *typename = lua_typename(L, tp);
    printf("%s", typename);
    if (tp == LUA_TTABLE || tp == LUA_TUSERDATA) {
      lua_pushvalue(L, i);
      const void *ptr = lua_topointer(L, -1);
      lua_pop(L, 1);
      printf("(%p)", ptr);
    }
  }
  printf("]\n");
}

static void read_entire_file(lua_State *L, const char *filename, Sound *sound) {
  // Open the file.
  CFURLRef file_url = CFURLCreateFromFileSystemRepresentation(
      NULL,                     // use default memory allocator
      (const UInt8 *)filename,  // path
      strlen(filename),         // path len
      false);                   // path is not a directory
  ExtAudioFileRef audio_file;
  OSStatus status    = ExtAudioFileOpenURL(file_url,
                                           &audio_file);
  jump_out_if_bad(status, "Failed to open file: '%s'", filename);
  
  UInt32 audio_desc_size = sizeof(sound->audio_desc);
  status = ExtAudioFileGetProperty(audio_file,
                                   kExtAudioFileProperty_FileDataFormat,
                                   &audio_desc_size,
                                   &sound->audio_desc);
  jump_out_if_bad(status, "Unable to read properties of audio file '%s'", filename);

  // Prepare initial buffer structure before we start reading.
  const size_t chunk_size = 8192;
  size_t full_size        = 0;
  char * full_ptr         = NULL;
  int bytes_per_frame     = sound->audio_desc.mBytesPerFrame;
  AudioBuffer buffer = {
    .mNumberChannels = sound->audio_desc.mChannelsPerFrame,
    .mDataByteSize   = chunk_size };
  AudioBufferList buffer_list = { .mNumberBuffers = 1, .mBuffers = buffer };
  UInt32 num_frames, total_frames = 0;

  do {
    // Update the buffer and num_frames to receive new data.
    AudioBuffer *buffer = &buffer_list.mBuffers[0];
    full_size    += chunk_size;
    full_ptr      = realloc(full_ptr, full_size);
    buffer->mData = full_ptr + full_size - chunk_size;
    num_frames    = chunk_size / bytes_per_frame;

    // Receive new data.
    OSStatus status = ExtAudioFileRead(audio_file, &num_frames, &buffer_list);
    jump_out_if_bad(status, "Error while reading file '%s'", filename);

    total_frames += num_frames;
  } while (num_frames);

  sound->bytes     = full_ptr;
  sound->num_bytes = total_frames * bytes_per_frame;
  sound->cursor    = full_ptr;

  status = ExtAudioFileDispose(audio_file);
  warn_if_bad(status, "failed to close the file '%s'\n", filename);
}

static void push_metatable(lua_State *L) {
  // Push table; return early if it already exists.
  if (luaL_newmetatable(L, sounds_mt) == 0) return;

  // If we get here, the table is pushed but is empty.
  lua_pushcfunction(L, delete_sound);
  lua_setfield(L, -2, "__gc");

  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  lua_pushcfunction(L, play_sound);
  lua_setfield(L, -2, "play");

  lua_pushcfunction(L, stop_sound);
  lua_setfield(L, -2, "stop");
}

// This pushes the sounds_mt.playing table to the top of the stack. It creates
// the table if it doesn't exist yet.
static void get_playing_table(lua_State *L) {
                                     // (Lua stack)
  push_metatable(L);                 // [sounds_mt]
  lua_getfield(L, -1, "playing");    // [sounds_mt, sounds_mt.playing]
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);                   // [sounds_mt]
    lua_newtable(L);                 // [sounds_mt, playing]
    lua_pushvalue(L, -1);            // [sounds_mt, playing, playing]
    lua_setfield(L, -3, "playing");  // [sounds_mt, playing]
  }
  lua_remove(L, -2);                 // [sounds_mt.playing ~= nil]
}

// Function to load an audio file.
static int load_file(lua_State *L) {
  update(L);  // Release any stopped-playing sounds.

  const char *filename = luaL_checkstring(L, 1);

  // push new_obj = {}
  Sound *sound = lua_newuserdata(L, sizeof(Sound));
  *sound = (Sound) {
    .queue      = NULL,
    .bytes      = NULL,
    .num_bytes  = 0,
    .cursor     = NULL,
    .index      = next_index++,
    .is_running = 0,
    .do_stop    = 0
  };
  push_metatable(L);        // push sounds_mt, our metatable
  lua_setmetatable(L, -2);  // setmetatable(new_obj, sounds_mt)

  read_entire_file(L, filename, sound);
  setup_queue_for_sound(L, sound);

  return 1;  // Return new_obj.
}

static void setup_queue_for_sound(lua_State *L, Sound *sound) {
  OSStatus status = AudioQueueNewOutput(&sound->audio_desc,
                                        sound_play_callback,
                                        sound,  // user data
                                        NULL, /* CFRunLoopGetCurrent(), */
                                        kCFRunLoopCommonModes,
                                        0,     // reserved flags; must be 0
                                        &sound->queue);
  jump_out_if_bad(status, "Error creating new audio output stream.");
  
  for (int i = 0; i < 2; ++i) {
    UInt32 buffer_byte_size = 4 * 1024;
    AudioQueueBufferRef buffer;
    status = AudioQueueAllocateBuffer(sound->queue,
                                      buffer_byte_size,
                                      &buffer);
    jump_out_if_bad(status, "Error priming audio buffers for playback.");
    sound_play_callback(sound,  // user data
                        sound->queue,
                        buffer);
  }

  // 0 --> decode all buffers; NULL --> no need for #decoded frames.
  status = AudioQueuePrime(sound->queue, 0, NULL);
  jump_out_if_bad(status, "Error priming audio queue.");
  
  status = AudioQueueAddPropertyListener(sound->queue,
                                         kAudioQueueProperty_IsRunning,
                                         running_status_changed,
                                         sound);  // user data
  jump_out_if_bad(status, "Error attaching play/stop listener to playback stream.");
}


///////////////////////////////////////////////////////////////////////////////
// Internal/metatable Lua functions.
///////////////////////////////////////////////////////////////////////////////

// We want to avoid deleting an object that's actively being played. To ensure
// that, we add a sound to sound_mt.playing when it starts playing, and remove
// it from that table when it stops.
static int delete_sound(lua_State* L) {
  update(L);  // Release any stopped-playing sounds.

  Sound *sound = (Sound *)luaL_checkudata(L, 1, sounds_mt);
  AudioQueueDispose(sound->queue, false);  // false --> asynchronous
  free(sound->bytes);

  return 0;
}

// Check for any sound objects in sounds_mt.playing that are done playing, and
// remove them.
static int update(lua_State *L) {
  get_playing_table(L);

  lua_pushnil(L);
  while (lua_next(L, -2)) {
    Sound *sound = (Sound *)lua_touserdata(L, -1);  // Grab the value.
    lua_pop(L, 1);  // Pop the value.
    if (!sound->is_running) {
      // Save a copy of the key for the following lua_next call.
      lua_pushvalue(L, -1);
      lua_pushnil(L);
      lua_settable(L, -4);
    }
  }

  return 0;
}

// Function to play a loaded sound.
static int play_sound(lua_State *L) {
  update(L);  // Release any stopped-playing sounds.

  Sound *sound = (Sound *)luaL_checkudata(L, 1, sounds_mt);

  // Don't do anything if the sound is already playing.
  if (sound->is_running && !sound->do_stop) return 0;

  sound->do_stop = 0;
  sound->is_running = 1;

  OSStatus status = AudioQueueStart(sound->queue, NULL);  // NULL --> start now
  jump_out_if_bad(status, "Error starting playback.");

  // Save another reference to the sound so it doesn't get garbage collected early.
  get_playing_table(L);
  lua_pushinteger(L, sound->index);
  lua_pushvalue(L, 1);  // -> [self, sounds_mt.playing, self.index, self]
  lua_settable(L, 2);   // Sets playing[self.index] = self.

  return 0;
}

static int stop_sound(lua_State *L) {
  update(L);  // Release any stopped-playing sounds.

  Sound *sound = (Sound *)luaL_checkudata(L, 1, sounds_mt);
  if (sound->is_running) {
    sound->do_stop = true;
    sound->cursor = sound->bytes;
  }
  return 0;  // Number of return values.
}


///////////////////////////////////////////////////////////////////////////////
// Internal callbacks.
///////////////////////////////////////////////////////////////////////////////

void sound_play_callback(void *user_data, AudioQueueRef queue,
                         AudioQueueBufferRef buffer) {

  Sound *sound = (Sound *)user_data;

  int bytes_per_frame = sound->audio_desc.mBytesPerFrame;

  UInt32 bytes_capacity = buffer->mAudioDataBytesCapacity;
  UInt32 num_bytes_left = sound->bytes + sound->num_bytes - sound->cursor;

  assert(num_bytes_left >= 0);

  int do_stop  = (num_bytes_left == 0 || sound->do_stop);
  if (do_stop) {
    // 2nd param may request an immediate stop.
    OSStatus status = AudioQueueStop(queue, sound->do_stop);
    warn_if_bad(status, "error while stopping a sound.\n");

    sound->is_running  = 0;
    sound->do_stop     = 0;
    sound->cursor      = sound->bytes;
    num_bytes_left     = sound->num_bytes;
    sound->num_to_skip = 2;
  }

  UInt32 bytes_to_copy = bytes_capacity;
  if (num_bytes_left < bytes_capacity) bytes_to_copy = num_bytes_left;

  memcpy(buffer->mAudioData, sound->cursor, bytes_to_copy);
  buffer->mAudioDataByteSize = bytes_to_copy;
  sound->cursor += bytes_to_copy;

  if (sound->num_to_skip) {
    sound->cursor = sound->bytes;
    sound->num_to_skip--;
  }

  OSStatus status = AudioQueueEnqueueBuffer(queue,
                                            buffer,
                                            0,
                                            NULL);
  warn_if_bad(status, "playback error passing audio data to system.\n");
}

void running_status_changed(void *user_data, AudioQueueRef queue,
                            AudioQueuePropertyID property) {
  UInt32 is_running = 0;
  UInt32 property_size = sizeof(is_running);
  OSStatus status = AudioQueueGetProperty(queue,
                                          kAudioQueueProperty_IsRunning,
                                          &is_running,
                                          &property_size);
  warn_if_bad(status, "error reading sound properties on play/stop update.\n");

  if (!is_running) {
    Sound *sound = (Sound *)user_data;
    sound->is_running = 0;
  }
}


///////////////////////////////////////////////////////////////////////////////
// Public functions, and data for them.
///////////////////////////////////////////////////////////////////////////////

// Data for the exported sounds table.
static const struct luaL_Reg sounds[] = {
  {"load", load_file},
  {"update", update},
  {NULL, NULL}
};

int luaopen_beatz_sounds(lua_State *L) {
  luaL_register(L, "sounds", sounds);
  // TEMP
  printf("C: %s called\n", __FUNCTION__);
  return 1;
}

