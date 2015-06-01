(in-package :sdl2-mixer)

(defun linked-version ()
  (c-let ((version sdl2-ffi:sdl-version :from (mix-linked-version)))
    (values (version :major) (version :minor) (version :patch))))

(autowrap:define-bitmask-from-enum (init-flags sdl2-ffi:mix-init-flags))

(defun init (&rest flags)
  (mix-init (mask-apply 'init-flags flags)))

(defun quit ()
  (mix-quit))

(autowrap:define-enum-from-constants (audio-format)
  sdl2-ffi:+audio-u8+
  sdl2-ffi:+audio-s8+
  sdl2-ffi:+audio-u16lsb+
  sdl2-ffi:+audio-s16lsb+
  sdl2-ffi:+audio-u16msb+
  sdl2-ffi:+audio-s16msb+
  sdl2-ffi:+audio-u16+
  sdl2-ffi:+audio-s16+
  sdl2-ffi:+audio-u16sys+
  sdl2-ffi:+audio-s16sys+)

(defun open-audio (frequency format channels chunksize)
  (check-rc (mix-open-audio frequency
                            (enum-value '(:enum (audio-format)) format)
                            channels chunksize)))

(defun close-audio ()
  (mix-close-audio))

(defun query-format ()
  (c-with ((freq :int)
           (fmt sdl2-ffi:uint16)
           (chans :int))
    (check-non-zero (mix-query-spec (freq &) (fmt &) (chans &)))
    (values freq (enum-key '(:enum (audio-format)) fmt) chans)))

(defun load-wav (sample-file-name)
  "Loads the sample specified by the sample-file-name. Returns a mix-chunk. sdl2-mixer must be initialized and open-audio should be called prior to."
  (autocollect (ptr)
      (check-null (mix-load-wav-rw (sdl-rw-from-file (namestring sample-file-name) "rb") 1))
    (mix-free-chunk ptr)))

(defun free-chunk (chunk)
  "Free the memory used in the chunk and then free the chunk itself. Do not free the chunk while it is playing; halt the channel it's playing on using halt-channel prior to freeing the chunk."
  (mix-free-chunk chunk))

(defun allocate-channels (channels)
  "Set the number of channels to be mixed. Opening too many channels may result in a segfault. This can be called at any time even while samples are playing. Passing a number lower than previous calls will close unused channels. It returns the number of channels allocated"
  ;;This supposedly never fails so no check is in place
  (mix-allocate-channels channels))

(defun volume (channel volume)
  "Set the volume on a given channel, pass -1 to set the volume for all channels. The volume may range from 0 to 128. Passing in a number higher than the maximum will automatically set it to the maximum while passing in a negatiev will automatically set it to 0. Returns the current volume of the channel"
  (mix-volume channel volume))

(defun play-channel (channel mix-chunk loops)
  "Plays the mix-chunk (sound effect) loops+1 times on a given channel. Passing -1 for the channel will play it on the first unreserved channel. Returns the channel the sample is played on"
  ;; The original Mix_PlayChannel function is just a function-like C preprocessor macro much like Mix_LoadWAV which was not in the spec. According to the docs Mix_PlayChannel is simply Mix_PlayChannelTimed with ticks set to -1 https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_frame.html
  (check-rc (mix-play-channel-timed channel mix-chunk loops -1)))

(defun halt-channel (channel)
  "Halt the channel or pass -1 to halt all channels. Always returns 0"
  (mix-halt-channel channel))
