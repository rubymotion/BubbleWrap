module BubbleWrap
  module Media
    module Error
      class InvalidPlayerType < StandardError; end
      class NilPlayerCallback < StandardError; end
    end

    class Player
      attr_reader :media_player
      ############
      # Playing Media

      # Plays media in the system-default modal controller
      # Takes same parameters as #play
      # NOTE: If you don't supply a :controller option,
      # the rootViewController will be used.
      def play_modal(content_url, options = {})
        play(content_url, options.merge(modal: true))
      end

      # @param [String, NSURL] content_url is either a local or remote string
      #   for the location of the media you're playing.
      #   NOTE: if you're playing a remote file, your server needs to support
      #   range requests for that URL.
      #
      # @param [Hash] options to open the AVPlayerController with
      # the form {
      #   ### These are properties of AVPlayerViewController



      #   allows_air_play: true/false; default false,
      #   control_style: [MPMovieControlStyle]; default MPMovieControlStyleDefault,
      #   end_playback_time: [Integer] end time (in seconds) for media; default is -1,
      #   initial_playback_time: [Integer] start time (in seconds) for media; default is -1,
      #   movie_source_type: [MPMovieSourceType] a "hint" so the player knows how to load the data type;
      #     either MPMovieSourceTypeFile or MPMovieSourceTypeStreaming; default is MPMovieSourceTypeUnknown
      #     which may delay playback,
      #   repeat_mode: [MPMovieRepeatMode] how the player repeats at the end of playback; defautl is
      #     MPMovieRepeatModeNone
      #   scaling_mode: [MPMovieScalingMode] scaling mode for movies; default is MPMovieScalingModeAspectFit
      #   should_autoplay: true/false; default true,
      #   use_application_audio_session: true/false; default true.
      #
      #   ### These are properties of just the ::Player
      #   delay_play: true/false, default false. If false then you have to manually call
      #     @media_player.play in your code
      #   modal: true/false; default false,
      #   controller: [UIViewController] used to present the player modally;
      #     default uses root view controller of window
      # }
      #
      # @block for when setup is done; use this block to present
      #   @media_player.view if options[:modal] == false
      #
      # EX
      #  From a local URL:
      #    file = File.join(App.resources_path, 'test.mp3')
      #    BW::Media::Player.play(NSURL.fileURLWithPath(file)) do |media_player|
      #      media_player.view.frame = some_view.bounds
      #      self.view.addSubview media_player.view
      #    end
      #
      #  From a remote URL:
      #    BW::Media::Player.play("http://www.hrupin.com/wp-content/uploads/mp3/testsong_20_sec.mp3") do |media_player|
      #      media_player.view.frame = some_view.bounds
      #      self.view.addSubview media_player.view
      #    end
      def play(content_url, options = {}, &block)
        options = {
          delay_play: false
        }.merge(options)

        display_modal = !!options[:modal]

        content_url = content_url.is_a?(NSURL) ? content_url : NSURL.URLWithString(content_url)
        player = AVPlayer.playerWithURL(content_url)
        player.addObserver(self, forKeyPath:"status", options:0, context:nil)
        player.automaticallyWaitsToMinimizeStalling = true


        @media_player = AVPlayerViewController.alloc.init.tap do |avvc|
          avvc.delegate = self
          avvc.showsPlaybackControls = true
          avvc.allowsPictureInPicturePlayback = false
          avvc.entersFullScreenWhenPlaybackBegins = true
          avvc.videoGravity = AVLayerVideoGravityResizeAspect
          avvc.requiresLinearPlayback = false
          avvc.player = player
        end

        # set_player_options(options)

        if display_modal
          @presenting_controller = options[:controller]
          @presenting_controller ||= App.window.rootViewController
          @presenting_controller.presentViewController(@media_player, animated:true, completion:nil)
        else
          if block.nil?
            raise Error::NilPlayerCallback, "no block callback given in #play; you need\
                                              to supply one if options[:modal] == false"
          end
          block.call(@media_player)
        end
      end

      # Stops playback for a Media::Player
      def stop
        if @media_player.is_a? AVPlayerViewController
          @presenting_controller.dismissViewControllerAnimated(true, completion:nil)
          @presenting_controller = nil
        else
          @media_player.player.pause
        end
        @media_player = nil
      end

      private

      def observeValueForKeyPath(keyPath, ofObject:object, change:ch, context:cx)
        mp 'observed'
        mp object

        if object == @media_player.player && keyPath == "status"
          case object.status
          when AVPlayerStatusFailed
            p "BW::Media::Player error: #AVPlayerStatusFailed"
          when AVPlayerStatusReadyToPlay
            p "BW::Media::Player succcess: AVPlayerStatusReadyToPlay"

            # video = @media_player.player.currentItem
            # mp video
            # video.seekToTime(video.currentTime, completionHandler: -> finished {
            #   mp 'seeking ... '
            #   if finished
            #     mp 'playing'
            #     @media_player.player.pause
                @media_player.player.play
            #   end
            # })
          when AVPlayerItemStatusUnknown
            p "BW::Media::Player error: #AVPlayerStatusFailed"
          end
          p 'remove observer'
          object.removeObserver(self, forKeyPath:"status", context:nil)
        end
      end

      # RubyMotion has a problem calling some objective-c methods at runtime, so we can't
      # do any cool `camelize` tricks.
      def set_player_options(options)
        # self.media_player.showsPlaybackControls
        # self.media_player.playbackControlsIncludeInfoViews
        # self.media_player.playbackControlsIncludeTransportBar
        # self.media_player.allowsPictureInPicturePlayback
        # self.media_player.contentOverlayView
        # self.media_player.entersFullScreenWhenPlaybackBegins
        # self.media_player.exitsFullScreenWhenPlaybackEnds
        # self.media_player.readyForDisplay
        # self.media_player.videoBounds
        # self.media_player.videoGravity
        # self.media_player.requiresLinearPlayback
        # self.media_player.unobscuredContentGuide
        # self.media_player.updatesNowPlayingInfoCenter
        # self.media_player.appliesPreferredDisplayCriteriaAutomatically
        # self.media_player.customInfoViewController

        # self.media_player.allowsAirPlay = options[:allows_air_play] if options.has_key? :allows_air_play
        # self.media_player.controlStyle = options[:control_style] if options.has_key? :control_style
        # self.media_player.endPlaybackTime = options[:end_playback_time] if options.has_key? :end_playback_time
        # self.media_player.initialPlaybackTime = options[:initial_playback_time] if options.has_key? :initial_playback_time
        # self.media_player.movieSourceType = options[:movie_source_type] if options.has_key? :movie_source_type
        # self.media_player.repeatMode = options[:repeat_mode] if options.has_key? :repeat_mode
        # self.media_player.scalingMode = options[:scaling_mode] if options.has_key? :scaling_mode
        # self.media_player.shouldAutoplay = options[:should_autoplay] if options.has_key? :should_autoplay
        # self.media_player.useApplicationAudioSession = options[:use_application_audio_session] if options.has_key? :use_application_audio_session
      end
    end
  end
end
