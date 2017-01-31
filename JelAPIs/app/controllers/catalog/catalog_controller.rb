include EncryDecryHelper

class Catalog::CatalogController < ApiController
	def jel_api1
		message = "This is a text"
		puts "Before encrypt message:#{message}"
		encrypted_msg = encrypt(message)
        puts "Encrypted Message:#{encrypted_msg}"
        decrypted_msg = decrypt(encrypted_msg)
        puts "Decrypted Message:#{decrypted_msg}"
		render json: {name: 'Jeyavel-catalog', action: 'jel_app1'}
	end
end
