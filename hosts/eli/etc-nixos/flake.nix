# Das ist /etc/nixos auf Elis Server. Absichtlich nur diese eine Datei.
#
# `nixos-rebuild switch` ohne `--flake` baut, was in /etc/nixos liegt.
# Nach der Neuinstallation vom 19.09.2026 lag dort die Ausgabe von
# nixos-infect: Rechnername `ubuntu`, ein alter Root-Schluessel, kein
# Nutzer eli, keine Dienste. Ein einziger vergessener Schalter haette
# den ganzen Tag zurueckgedreht.
#
# Jetzt zeigt /etc/nixos hierher, und hier steht nur: nimm das Repo.
# `nixos-rebuild switch` und
# `nixos-rebuild switch --flake github:real-life-org/infrastructure#eli`
# bauen damit dasselbe.
{
  description = "Elis Server wird aus real-life-org/infrastructure gebaut. Hier steht nichts weiter.";

  inputs.infrastruktur.url = "github:real-life-org/infrastructure";

  outputs = { infrastruktur, ... }: {
    nixosConfigurations.eli = infrastruktur.nixosConfigurations.eli;
  };
}
