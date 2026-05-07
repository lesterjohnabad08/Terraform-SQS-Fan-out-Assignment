#Define Bucket Source Name
variable "source_s3bucket_name" { 
  description = "Please enter source bucket name, please make it globally unique..."
  type        = string  
} 

#Uncomment this if email notification is required
/*
#email address where to send the Notifications
variable "email_address" { 
  description = "Please enter email address where to send the Notifications"
  type        = string
  #default = "abad5800@stthomas.edu"
} 
*/