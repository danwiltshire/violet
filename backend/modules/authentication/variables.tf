variable "auth0_allowed_logout_urls" {
  description = "Auth0 allowed logout URLs"
  type = list(string)
}

variable "auth0_allowed_web_origins" {
  description = "Auth0 allowed web origins (CORS)"
  type = list(string)
}

variable "auth0_callbacks" {
  description = "Auth0 callback URLs"
  type = list(string)
}

variable "auth0_identifier" {
  description = "Auth0 identifier"
  type = string
}
