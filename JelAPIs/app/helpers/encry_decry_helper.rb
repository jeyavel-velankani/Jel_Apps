require 'openssl'
require 'base64'

module EncryDecryHelper
  def self.included(base)
    base.extend self
  end

  def cipher
    OpenSSL::Cipher::Cipher.new('aes-256-cbc')  # ('aes-256-cbc')
  end

  def cipher_key
    'jabcderfghfhfddd!'
  end

  def decrypt(value)
    ci = cipher.decrypt
    ci.key = Digest::SHA256.digest(cipher_key)
    ci.update(Base64.decode64(value.to_s)) + ci.final
  end

  def encrypt(value)
  	ci = cipher.encrypt
    ci.key = Digest::SHA256.digest(cipher_key)
    Base64.encode64(ci.update(value.to_s) + ci.final)
  end
end