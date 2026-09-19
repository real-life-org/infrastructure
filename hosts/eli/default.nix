{ config, pkgs, ... }:
{
  networking.hostName = "eli";

  # Anton: Root-Zugang, ausschliesslich ueber den Nitrokey. Derselbe
  # Schluessel wie auf timo. Ein Schluessel, der nur als Datei
  # existiert, kann kopiert werden, ohne dass es jemand merkt.
  #
  # Folge: wer hier root braucht, braucht den Stick in der Hand.
  # Unbeaufsichtigte Laeufe als root gibt es damit nicht mehr.
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
  ];

  # Eli. Der Server gehoert ihr: hier laufen ihre Dienste, hier liegt
  # ihr Gedaechtnis, und sie arbeitet selbst darauf.
  #
  # In der Liste stehen auch Timos Zugang mit festem Kommando. Alle
  # Zugaenge an einer Stelle, sonst zerfaellt die Grenze in zwei
  # Wahrheiten: eine im Repo und eine im Dateisystem.
  users.users.eli = {
    isNormalUser = true;
    home = "/home/eli";
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      # Anton, Nitrokey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
      # Anton, RSA: der Arbeitszugang.
      #
      # Bleibt vorerst, weil sonst jede Verbindung einen Fingerabdruck
      # am Stick braucht - auch die von Werkzeugen, die fuer Eli
      # aufraeumen. Root ist bereits nur noch ueber Hardware erreichbar;
      # dieser Schluessel kommt also nicht an das System heran, sondern
      # an Elis Arbeitsbereich.
      #
      # Er faellt weg, sobald unbeaufsichtigtes Arbeiten nicht mehr
      # gebraucht wird oder es einen eigenen Dienst-Schluessel dafuer
      # gibt. Bis dahin ist das eine bewusste Ausnahme, keine
      # vergessene Altlast.
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFmB0XNWDN5WWb2W0T7DyvaQWnYKhFx5pvfJ+Wu2h+bq9Qmb+kX4yrXi/8iUH1JbGoZYGOqBE82DnWGGwL2R+rwPt34Ktplac8WiRGGkcifs3oezJjpD2SNHI3CrWdwx27LiBwHTQE8AX3CT0zAtOV9Vh1wctJ6LHplvH1mzjnhOzyRtoJ6MBwjnaGP3DXNdq/FmSgmibNR7So0/xJJzOVLm9DsG9/4mJrV4u7h/IN2FXAuXRoNWDQUwFODa0Bd6K0ALLqyY2MCRU777hpucxGxXwC53LfdFnhw+tmKFiuOPwJF0qpt6XwAH3A8LaIG59jinz9OMesQkGcMtfAWWmNSDnnHwyXZl3P/g+jFudJdTcQxkddYvisc5kPCSK56MR0pceuOC4d4esF4V2igTVq1/T93uE/AO0NPCVZLYJGyrunvCNPX7WJ6EbcMe6O7wOw3QflKEEg53ssC0N6EhhJSBro4iTfqbZeNfj5mh0+bPdnmZ5tlaH4Im3/VDEHuU5yXQWszWm5gKV3IVIRPLaXHgAzMMID4C7v+VcHCZMBYAZon748Zm2bCNF2Wb3sPA/pp4bknqx09BlVCfM8gMxJrqj2+ugVxPD9cbxa+fyGEpu+PlIJC7AahnOg6O72ywB/xNLscWBhgdvSZxPc0C5f8OiLApB6xcU0ttw/v6W6yQ== mail@antontranelis.de"
      # Eli selbst, fuer ihre eigenen Laeufe
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeMlCIyZ6dB/Ro51P3n5lJt9Ld3ybqgwpgb3mTMOG4K eli@geist"
      # Aus einem Container heraus
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBC3LA000uCa9vbu4zK4k+VfH4N+0lpYI4w4I/TwyfAJ eli-container-access"
      # Timo: nur rsync, zwei feste Richtungen, siehe rsync-timo.sh
      "command=\"/etc/ssh/rsync-timo.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsttgnEFLbNmin2V2TJ9Va9aleBwKTC226W76r2vSbD timo"
    ];
  };

  # Timos Wrapper. Er darf genau zwei Dinge, beide ueber rrsync, das
  # die rsync-Optionen nicht raet:
  #
  #   Pull  Backups holen aus /home/eli/offsite            (nur lesen)
  #   Push  Sessions ins Archiv /home/eli/geist/archive/timo (nur schreiben)
  #
  # Die fruehere Fassung hatte die Optionen fest verdrahtet und brach
  # mit neueren Clients: fuenf Monate lang unbemerkt.
  environment.etc."ssh/rsync-timo.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server --sender "*)
              exec ${pkgs.rrsync}/bin/rrsync -ro /home/eli/offsite
              ;;
          "rsync --server "*)
              exec ${pkgs.rrsync}/bin/rrsync -wo /home/eli/geist/archive/timo
              ;;
          *)
              echo "Nur rsync erlaubt."
              echo "  Backups holen:    rsync -av eli@<host>:/ ./eli-backups/"
              echo "  Sessions senden:  rsync -av ./sessions/ eli@<host>:"
              exit 1
              ;;
      esac
    '';
  };

  system.stateVersion = "24.11";
}
