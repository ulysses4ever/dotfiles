# piano.nix — the Arturia MicroLab mk3 plays a grand piano, live (2026-11-07).
# Nothing records.
#
# Plugging the keyboard in starts FluidSynth as a user service, `piano`, loaded
# with the Salamander Grand Piano; unplugging it stops the service and frees the
# 1.2 GiB of samples. The sound goes to the default output, whichever that is at
# the moment: the monitor over HDMI, or headphones once they are in the jack.
# `systemctl --user status piano` says whether it is up, and
# `journalctl --user -u piano` what it made of the keyboard.
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
  commands = pkgs.writeText "piano.cmd"
    (lib.concatMapStrings (ch: "cc ${toString ch} 91 100\n") (lib.range 0 15));

  piano = pkgs.writeShellScript "piano" ''
    # The user manager lingers, so at boot it starts this before anyone has
    # logged in, and /dev/snd/* is root:audio plus an ACL for the active
    # session. Without it FluidSynth would come up with no MIDI input, and stay
    # that way. So wait for the login.
    until [[ -r /dev/snd/seq && -w /dev/snd/seq ]]; do ${pkgs.coreutils}/bin/sleep 5; done

    # -z 256: 5.3 ms blocks at 48 kHz, the graph's rate.
    # -g 0.4: the loudest the keyboard plays, ten keys at velocity 127 and then
    #   a glissando over all 25, the hold on throughout, peaks at -0.5 dBFS with
    #   the reverb, so nothing clips even at full volume. The default, 0.2, is
    #   6 dB quieter.
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
      -g 0.4 -C 0 -f ${commands} \
      "${salamander}/share/soundfonts/SalamanderGrandPiano-V3+20200602.sf2" \
      < <(exec ${pkgs.coreutils}/bin/sleep infinity)
  '';
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
      After = [ "sys-subsystem-sound-devices-microlab.device" "pipewire.service" ];
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
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=/nonexistent" ];
    };
  };
}
