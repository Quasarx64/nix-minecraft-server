let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFsCtzp087hUufRppH005DbcRUjas0IzVJfMYUQ+Td8 dan.rei.wilcox@gmail.com";
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoI9mIzgNcATXD9x5hkHs/fhFw1SC41MbDMBrp8fmYf root@nixos";
in
{
  "rcon-password.age".publicKeys = [ user server];
}
