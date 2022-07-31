resource "consul_certificate_authority" "connect" {
  connect_provider = "vault"

  config = {
    Address             = data.tfe_outputs.hcp_vault.values.vault_private_addr
    Token               = var.vault_token
    RootPKIPath         = "connect_root"
    IntermediatePKIPath = "connect_inter"
    LeafCertTTL         = "1h"
    RotationPeriod      = "144h"
    IntermediateCertTTL = "288h"
    PrivateKeyType      = "ec"
    PrivateKeyBits      = 256
    Namespace           = "admin"
  }
}