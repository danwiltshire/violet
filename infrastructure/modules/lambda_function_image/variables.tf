variable "function_name" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "additional_policy_documents" {
  type    = list(string)
  default = []
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "architecture" {
  type = string

  default = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "Valid values for var: architecture are (arm64, x86_64)."
  }
}

variable "memory_size" {
  type = number
}

variable "timeout" {
  type = number
}

variable "image" {
  type = object({
    uri     = string
    command = list(string)
  })
}

variable "description" {
  type = string
}

variable "enable_iam_function_url" {
  type    = bool
  default = false
}
