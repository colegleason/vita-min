# == Schema Information
#
# Table name: email_login_requests
#
#  id                    :bigint           not null, primary key
#  mailgun_status        :string
#  email_access_token_id :bigint           not null
#  mailgun_id            :string
#  visitor_id            :string           not null
#
# Indexes
#
#  index_email_login_requests_on_email_access_token_id  (email_access_token_id)
#  index_email_login_requests_on_mailgun_id             (mailgun_id)
#  index_email_login_requests_on_visitor_id             (visitor_id)
#
class EmailLoginRequest < ApplicationRecord
  belongs_to :email_access_token
  validates_presence_of :visitor_id
end
