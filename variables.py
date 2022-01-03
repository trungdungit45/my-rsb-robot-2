from RPA.Robocorp.Vault import Vault

secret = Vault().get_secret("settings")
rsb_oder_data_url = secret["rsb_oder_data_url"]
rsb_web_url = secret["rsb_web_url"]