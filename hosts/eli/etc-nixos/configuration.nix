# Das ist /etc/nixos/configuration.nix auf Elis Server. Absichtlich nur
# ein Abbruch mit Hinweis.
#
# `nixos-rebuild switch` ohne `--flake` baut aus dieser Datei. Nach der
# Neuinstallation vom 19.09.2026 lag hier die Ausgabe von nixos-infect:
# Rechnername `ubuntu`, ein alter Root-Schluessel, kein Nutzer eli,
# keine Dienste. Ein einziger vergessener Schalter haette den ganzen
# Tag zurueckgedreht.
#
# Warum kein Wrapper-Flake, das auf das Repo zeigt: ein Flake braucht
# eine flake.lock, und die laege im Nix-Store, wo nichts geschrieben
# werden kann. Eine eingecheckte Lock-Datei wiederum pinnt zwangslaeufig
# einen aelteren Stand desselben Repos - der schlichte Befehl wuerde
# dann still auf diesen Stand zurueckbauen. Ein Abbruch mit Hinweis ist
# ehrlicher als ein Erfolg, der etwas anderes baut.
{ ... }:
throw ''

  Dieser Server wird aus dem Repo real-life-org/infrastructure gebaut,
  nicht aus /etc/nixos. Der Befehl dafuer:

      nixos-rebuild switch --flake github:real-life-org/infrastructure#eli

  Siehe hosts/eli/README.md, Abschnitt "Ausrollen".
''
