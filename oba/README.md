
* ### Pasword encryption without gems
``` ruby
  def encrypt_password
    if self.password.present?
      self.password_salt = User.hash_to_string(OpenSSL::Random.random_bytes(16))
      self.password_hash = User.hash_to_string(
        OpenSSL::PKCS5.pbkdf2_hmac(
          self.password, self.password_salt, ITERATIONS, DIGEST.length, DIGEST
        )
      )
    end
  end
  
  def self.hash_to_string(password_hash)
    password_hash.unpack('H*')[0]
  end
```

* ### Pagy
The best gem to make pagination 
https://github.com/ddnexus/pagy
