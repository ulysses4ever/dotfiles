# piano.nix — the Arturia MicroLab mk3 plays a grand piano, live (2026-11-07).
# Nothing records.
#
# Plugging the keyboard in starts FluidSynth as a user service, `piano`, loaded
# with the Salamander Grand Piano; unplugging it stops the service and frees the
# 1.2 GiB of samples. The sound goes to the default output, whichever that is at
# the moment: the monitor over HDMI, or headphones once they are in the jack.
# `systemctl --user status piano` says whether it is up, and
# `journalctl --user -u piano` what it made of the keyboard. PianoBooster and
# Neothesia, for practice, play through the same piano (2026-11-08).
{ config, lib, pkgs, ... }:

let
  # The Salamander Grand Piano: a Yamaha C5 sampled at 16 velocities by
  # Alexander Holm, CC-BY 3.0, in FreePats' SF2 build. The SFZ original also
  # sounds the hammers, pedal and strings on release, which SF2 cannot express;
  # it would take sfizz, a JACK client whose MIDI and audio nothing here would
  # connect, where FluidSynth connects both itself.
  salamander = pkgs.stdenvNoCC.mkDerivation {
    pname = "salamander-grand-piano-sf2";
    version = "3+20200602";
    src = pkgs.fetchurl {
      url = "https://freepats.zenvoid.org/Piano/SalamanderGrandPiano/SalamanderGrandPiano-SF2-V3+20200602.tar.xz";
      hash = "sha256-Fe2wYde6YNWDMvctuo+M5AmIBIzHA/k15jIPN9ZQ4hM=";
    };
    # 1.2 GiB unpacked: straight into $out, not through the build directory.
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/soundfonts $out/share/doc/salamander-grand-piano
      tar -xJf $src --strip-components=1 -C $out/share/soundfonts
      mv $out/share/soundfonts/readme.txt $out/share/doc/salamander-grand-piano/
    '';
  };

  # Every other instrument, and the drums, for the parts of a song that
  # PianoBooster plays: GeneralUser GS, a General MIDI set of 30 MB. Without
  # it they all came out as the piano, and the drums not at all (2026-11-08).
  # FluidSynth asks the SoundFont loaded last first, so with the Salamander
  # loaded after this one, the piano (bank 0, program 0, which is also what
  # the keyboard plays) is still the Salamander.
  generalMidi = "${pkgs.soundfont-generaluser-gs}/share/soundfonts/GeneralUser-GS.sf2";

  # nixpkgs builds FluidSynth without its PipeWire driver, the one that keeps
  # the delay between key and sound short: the synth renders in PipeWire's
  # realtime thread and asks the graph for its own block size (-z). The stock
  # build's PulseAudio driver gets at best the pulse server's 256-frame
  # minimum, with the client's own buffer on top of that.
  fluidsynth = pkgs.fluidsynth.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.pipewire ];
  });

  # Run once the piano is loaded. FluidSynth leaves each channel's reverb send
  # (CC 91) at 0 and this SoundFont sets none, so out of the box the piano
  # sounds as dry as the microphones heard it, a hand's width over the strings.
  # At 100 the reverb sits 15 dB under the piano, measured on a rendered
  # phrase; 127 is the most a send goes, 13 dB under. All sixteen channels, so
  # it holds on whichever one the keyboard sends.
  #
  # Then the touch. Velocity straight from the keys spans too much for these
  # short keys and small speakers: a tap at 16 peaked 54 dB under one at 127
  # and never rose above -55 dBFS, so soft notes came out faint and gone at
  # once while firmer ones rang on, which on 2026-11-07 sounded "quite low,
  # with a strangely varying length". The MIDI router maps velocity v to
  # 57 + 0.55 v instead: 127 stays 127, 16 becomes 66, and taps from 16 to 127
  # now peak between -29 and -12 dBFS and ring 0.4 to 1.1 s. Clearing the
  # router also drops its pass-through rules, so the other kinds of event
  # get theirs back.
  #
  # Only for the keyboard's own channel: the MicroLab sends on channel 15, 14
  # counting from 0 as FluidSynth does (seen 2026-11-08). The parts a song
  # brings, the other hand from PianoBooster and its backing, are on other
  # channels and keep the dynamics they were written with. "15 13" is the
  # router's inverted window: every channel but 14. If the keyboard is ever
  # set to send on another channel, the 14s here follow it.
  commands = pkgs.writeText "piano.cmd" (
    lib.concatMapStrings (ch: "cc ${toString ch} 91 100\n") (lib.range 0 15)
    + ''
      router_clear
      router_begin note
      router_chan 14 14 1 0
      router_par2 0 127 0.55 57
      router_end
      router_begin note
      router_chan 15 13 1 0
      router_end
    ''
    + lib.concatMapStrings (type: "router_begin ${type}\nrouter_end\n")
      [ "cc" "prog" "pbend" "cpress" "kpress" ]
  );

  piano = pkgs.writeShellScript "piano" ''
    # The user manager lingers, so at boot it starts this before anyone has
    # logged in, and /dev/snd/* is root:audio plus an ACL for the active
    # session. Without it FluidSynth would come up with no MIDI input, and stay
    # that way. So wait for the login.
    until [[ -r /dev/snd/seq && -w /dev/snd/seq ]]; do ${pkgs.coreutils}/bin/sleep 5; done

    # -z 256: 5.3 ms blocks at 48 kHz, the graph's rate.
    # -g 1.0: on rendered two-hand passages, forte playing comes out at about
    #   -15 LUFS, near the -14 YouTube brings music to, and mezzo-forte at -19.
    #   The hardest playing would then peak at +6 dBFS, which the limiter
    #   (below) holds at -1. At 0.4, safe without one, the piano was quieter
    #   than YouTube at the same volume (2026-11-08).
    # -C 0: a piano has no chorus.
    # midi.autoconnect subscribes to every MIDI port there is, and to each one
    # that appears later: the keyboard, whenever it comes up after this starts.
    #
    # FluidSynth runs only while something holds it open: its shell on stdin, a
    # MIDI file playing, or its TCP shell (-s). The TCP shell is what upstream's
    # unit and home-manager's services.fluidsynth use, and it listens
    # unauthenticated on every interface of a host with no firewall
    # (modules/network.nix). So the stdin shell, on a pipe nothing writes to.
    exec ${fluidsynth}/bin/fluidsynth \
      -a pipewire -z 256 -r 48000 \
      -m alsa_seq -o midi.autoconnect=1 -o midi.alsa_seq.id=piano \
      -g 1.0 -C 0 -f ${commands} \
      ${generalMidi} "${salamander}/share/soundfonts/SalamanderGrandPiano-V3+20200602.sf2" \
      < <(exec ${pkgs.coreutils}/bin/sleep infinity)
  '';

  # A peak limiter between FluidSynth and the speakers, in a PipeWire process
  # of its own: x42's digital peak limiter, 64 samples (1.3 ms) of
  # look-ahead at 48 kHz. swh's fast look-ahead limiter takes 5 ms. PipeWire
  # has no limiter of its own; its clamp would clip.
  #
  # Its input is a capture stream that connects to nothing by itself, and not
  # a sink: a sink can become the default output whenever it is the only one,
  # as when the monitor sleeps and its HDMI audio goes, and then every other
  # stream would play through the piano's limiter. FluidSynth reaches the
  # input by name (PIPEWIRE_NODE). The output follows the default sink.
  limiter = pkgs.writeText "piano-limiter.conf" ''
    context.properties = { log.level = 0 }
    context.spa-libs = {
      audio.convert.* = audioconvert/libspa-audioconvert
      support.*       = support/libspa-support
    }
    context.modules = [
      { name = libpipewire-module-rt, flags = [ ifexists nofail ] }
      { name = libpipewire-module-protocol-native }
      { name = libpipewire-module-client-node }
      { name = libpipewire-module-adapter }
      { name = libpipewire-module-filter-chain
        args = {
          node.description = "Piano limiter"
          media.name       = "Piano limiter"
          filter.graph = {
            nodes = [ {
              type    = lv2
              name    = dpl
              plugin  = "http://gareus.org/oss/lv2/dpl#stereo"
              control = { threshold = -1.0, release = 0.05 }
            } ]
          }
          audio.channels = 2
          audio.position = [ FL FR ]
          capture.props  = { node.name = "piano_limiter", node.autoconnect = false }
          playback.props = { node.name = "piano_limiter.output", node.passive = true }
        }
      }
    ]
  '';

  # Practice apps (2026-11-08). PianoBooster plays a song, waits for the right
  # notes, scores them, a hand at a time, and plays the other parts itself;
  # Neothesia shows any MIDI song as falling notes. Neither should sound your
  # keys: the piano already does, straight from the keyboard and without an
  # app's delay, so an app doing it too would mean every note twice.
  #
  # PianoBooster's output is the piano, so the parts it plays come out of the
  # same piano, and its right- and wrong-note sounds, which are your keys
  # played back, are None. Neothesia has no such switch: it plays the song's
  # notes for the part you play along with the rest, so with the piano as its
  # output your part would sound twice. Its output is No Output instead: you
  # hear what you play, and the falling notes wait for it, but it plays no
  # other parts. Both are only first settings; either app can change them.
  #
  # The apps find these ports by names that change (piano-apps.py says how),
  # so each starts through a wrapper that writes the current names first.
  midiPorts = pkgs.runCommandCC "midi-ports" { buildInputs = [ pkgs.alsa-lib ]; } ''
    mkdir -p $out/bin
    $CC -O2 -Wall -o $out/bin/midi-ports ${./midi-ports.c} -lasound
  '';
  practiceApp = pkg: pkgs.symlinkJoin {
    inherit (pkg) name;
    paths = [ pkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # The wrapper stops at a command that fails, and the app with it.
    postBuild = ''
      wrapProgram $out/bin/${pkg.pname} \
        --run '${pkgs.python3}/bin/python3 ${./piano-apps.py} ${pkg.pname} ${midiPorts}/bin/midi-ports || true'
    '';
  };
in
{
  # The keyboard's arrival pulls the service in, through the user manager, and
  # the alias names its device the same whichever USB port it is in, for the
  # service to bind to. systemd 260 makes the device unit of a sound card's
  # control node, not of the card (99-systemd.rules).
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="controlC*", ATTRS{idVendor}=="1c75", ATTRS{idProduct}=="020c", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/sys/subsystem/sound/devices/microlab", ENV{SYSTEMD_USER_WANTS}+="piano.service"
  '';

  # FluidSynth locks the samples in RAM (synth.lock-memory, on by default), so
  # a note never waits on swap, and swap here runs full. A user manager may lock
  # 8 MiB by default; the unit asks for no limit and is held to the manager's
  # own. This raises that, from the user manager's next start, which with
  # lingering on is the next boot. Until then the lock fails and FluidSynth
  # plays anyway, without a word: VmLck in /proc/<pid>/status says which.
  systemd.services."user@".serviceConfig.LimitMEMLOCK = "infinity";

  home-manager.users.artem.systemd.user.services.piano = {
    Unit = {
      Description = "Grand piano on the MicroLab mk3 (FluidSynth)";
      # No [Install]: only the keyboard starts it, and it stops with the keyboard.
      BindsTo = [ "sys-subsystem-sound-devices-microlab.device" ];
      Requires = [ "piano-limiter.service" ];
      After = [ "sys-subsystem-sound-devices-microlab.device" "pipewire.service" "piano-limiter.service" ];
      # FluidSynth never reconnects its stream, so restart along with PipeWire.
      PartOf = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${piano}";
      Restart = "on-failure";
      LimitMEMLOCK = "infinity";
      # PipeWire asks for its realtime thread through the desktop portal when
      # the session bus has one, and doesn't wait for the answer. Here the
      # portal drops the request without a trace, and the synth would render at
      # normal priority, while rtkit, asked directly, grants it (2026-11-07). With
      # no session bus to reach, PipeWire asks rtkit; nothing else here uses it.
      #
      # The stream goes to the limiter, and if the limiter is not there it
      # waits for it rather than reach the speakers unlimited, where the
      # hardest playing would clip.
      Environment = [
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/nonexistent"
        "PIPEWIRE_NODE=piano_limiter"
        "PIPEWIRE_PROPS={node.dont-fallback=true}"
      ];
    };
  };

  # A switch to a new PipeWire stops it, and the piano with it (PartOf above),
  # then leaves PipeWire to its sockets: it starts again on the next
  # connection, but nothing starts the piano, which only the keyboard's
  # arrival does, and it stayed silent (2026-11-18). So each start of PipeWire
  # brings the piano back, when the keyboard is there.
  home-manager.users.artem.systemd.user.services.piano-after-pipewire = {
    Unit = {
      Description = "Start the piano again with PipeWire, if the MicroLab is plugged in";
      After = [ "pipewire.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/sh -c '${config.systemd.package}/bin/systemctl --user is-active -q sys-subsystem-sound-devices-microlab.device && ${config.systemd.package}/bin/systemctl --user start --no-block piano.service || true'";
    };
    Install.WantedBy = [ "pipewire.service" ];
  };

  home-manager.users.artem.home.packages = map practiceApp [ pkgs.pianobooster pkgs.neothesia ];

  home-manager.users.artem.systemd.user.services.piano-limiter = {
    Unit = {
      Description = "Peak limiter after the MicroLab piano (x42-dpl)";
      # Up while the piano is, which requires it.
      StopWhenUnneeded = true;
      After = [ "pipewire.service" ];
      PartOf = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${config.services.pipewire.package}/bin/pipewire -c ${limiter}";
      Restart = "on-failure";
      # Realtime through rtkit, as for the piano above.
      Environment = [
        "LV2_PATH=${pkgs.x42-plugins}/lib/lv2"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/nonexistent"
      ];
    };
  };
}
