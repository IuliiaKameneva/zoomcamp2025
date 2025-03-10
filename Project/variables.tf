variable "google_credentials" {
  description = "Credentials of Service Account in GCP Console" 
  default = "/workspace/essencial_data/fair-canto-447119-p5-9091e1a7224d.json"
}

variable "project" {
  description = "Project ID"
  default     = "fair-canto-447119-p5"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "region" {
  description = "Region"
  default     = "us-central"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "project_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucker Name"
  default     = "project-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucker Storage Class"
  default     = "STANDART"
}