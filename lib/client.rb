require 'simple_host_monitoring'
require_relative './user'
require_relative './role'
require_relative './timezone'

module BlackStack
  class Client < Sequel::Model(:client)
    BlackStack::Client.dataset = BlackStack::Client.dataset.disable_insert_output
    
    one_to_many :users, :class=>:'BlackStack::User', :key=>:id_client
    many_to_one :timezone, :class=>:'BlackStack::Timezone', :key=>:id_timezone
    many_to_one :billingCountry, :class=>:'BlackStack::LnCountry', :key=>:billing_id_lncountry
    many_to_one :user_to_contect, :class=>'BlackStack::User', :key=>:id_user_to_contact
  
  
    # ----------------------------------------------------------------------------------------- 
    # Arrays
    # 
    # 
    # ----------------------------------------------------------------------------------------- 
  
    # returns the workers belong this clients, that have not been deleted
    def not_deleted_workers()
      BlackStack::Worker.where(:id_client=>self.id, :delete_time=>nil)
    end
  
    # returns the hosts where this client has not-deleted workers, even if the host is not belong this client
    def hosts()
      BlackStack::LocalHost.where(id: self.not_deleted_workers.select(:id_host).all.map(&:id_host))
    end
  
    # returns the hosts belong this client
    def own_hosts()
      BlackStack::LocalHost.where(:id_client=>self.id, :delete_time=>nil)
    end
    
    # ----------------------------------------------------------------------------------------- 
    # Configuration
    #
    #
    # ----------------------------------------------------------------------------------------- 
  
    # retorna true si la 5 variables (billing_address, billing_city, billing_state, billing_zipcode, billing_id_lncountry) tienen un valor destinto a nil o a un string vacio.
    def hasBillingAddress?
      if (
        self.billing_address.to_s.size == 0 || 
        self.billing_city.to_s.size == 0 || 
        self.billing_state.to_s.size == 0 || 
        self.billing_zipcode.to_s.size == 0 ||
        self.billing_id_lncountry.to_s.size == 0
      )
        return false
      else
        return true
      end
    end
  
    # retorna un array de objectos UserRole, asignados a todos los usuarios de este cliente
    def user_roles
      a = []
      self.users.each { |o| 
        a.concat o.user_roles 
        # libero recursos
        GC.start
        DB.disconnect
      }
      a    
    end
    
    # si el cliente no tiene una zona horaria configurada, retorna la zona horaria por defecto
    # excepciones: 
    # => "Default timezone not found."
    def getTimezone()
      ret = nil   
      if (self.timezone != nil)
        ret = self.timezone
      else
        ret = BlackStack::Timezone.where(:id=>BlackStack::Pampa::id_timezone_default).first
        if (ret == nil)
          raise "Default timezone not found."
        end
      end
      return ret
    end
  
    # llama a la api de postmark preguntando el reseller email configurado para este clietne fue ferificado
    def checkDomainForSSMVerified()
			return_message = {}  
      domain = self.domain_for_ssm
      email = self.from_email_for_ssm
      id = ''
      client = ''
      if domain != nil && email != nil
        begin
          # create postmark client
					client_postmark = Postmark::AccountApiClient.new(POSTMARK_API_TOKEN, secure: true)      
					
          # get signature
					# more info: https://github.com/wildbit/postmark-gem/wiki/Senders
					#
					# TODO: this first strategy is not scalable if we handle a large list of signatures.
					# sign = client_postmark.signatures.select { |sign| sign[:domain]==domain }.first
					# 
					# this other approach is a bit more scalable, but anyway we need to call the API 
					# with filering by the domain.
					# 
          # 
          # TODO: this code is a replication from the filter ?memeber/filter_update_reseller_signature
          # Refer this issue for more information: https://github.com/leandrosardi/blackstack/issues/95
          #
					pagesize = 30 # TODO: increase this value to 300 for optimization
					i = 0
					j = 1
					sign = nil
					while j>0 && sign.nil?
						buff = client_postmark.get_signatures(offset: i, count: pagesize)
						j = buff.size
						i += pagesize
						sign = buff.select { |s| s[:domain]==domain }.first
					end # while
					
					# if signature has been found?
          if sign.nil?
						# sincronizo con la central
						return_message[:status] = "Client Signature Not Found"
						return_message[:value] = client[:id]
						return return_message.to_json 
					else
            id = sign[:id]
						client = client_postmark.get_sender(id)
            if !client[:confirmed]
              self.domain_for_ssm_verified = false
              self.save  
              return_message[:status] = "No Verified"
              return_message[:value] = client[:id]
              return return_message.to_json 
            else
              self.domain_for_ssm_verified = true
              self.save  
              return_message[:status] = "success"
              return_message[:value] = client[:id]
              return return_message.to_json 
            end
          end
        rescue Postmark::ApiInputError => e
          return_message[:status] = e.to_s
          return return_message.to_json
          #return e
        rescue => e
          return_message[:status] = e.to_s
          return return_message.to_json
          #return e
        end
      else
        return_message[:status] = 'error'
        return_message[:value] = ''
        return return_message.to_json
      end # checkDomainForSSMVerified
    end
    
    # retorna true si el cliente esta configurado para usar su propia nombre/email en el envio de notificaciones 
    def resellerSignature?
      self.from_name_for_ssm.to_s.size>0 && self.from_email_for_ssm.to_s.size>0 
    end
  
    # retorna true si el cliente esta configurado para usar su propia nombre/email en el envio de notificaciones, y si el email fue verificado en postmark 
    def resellerSignatureEnabled?
=begin # TODO: Mover esto a un proceso asincronico
      # si el cliente esta configurado para usar su propia nombre/email 
      if self.resellerSignature?
        # pero el email fue verificado en postmark
        if self.domain_for_ssm_verified==nil || self.domain_for_ssm_verified!=true
          # hago la verificacion contra postmark
          self.checkDomainForSSMVerified   
        end          
      end
=end
      # return
      resellerSignature? == true && self.domain_for_ssm_verified==true
    end
    
    # retorna el email configurado y confirmado en PostMark para cuenta reseller, o retorna el email por defecto
    def resellerSignatureEmail
      # configuracion de cuenta reseller
      if self.resellerSignatureEnabled?
        return self.from_email_for_ssm.to_s
      else
        return NOTIFICATIONS[:from_email]
      end
    end
  
    # retorna el nombre configurado para cuenta reseller, solo si el email esta confirmado en PostMark; o retorna el email por defecto
    def resellerSignatureName
      # configuracion de cuenta reseller
      if self.resellerSignatureEnabled?
        return self.from_name_for_ssm.to_s
      else
        return NOTIFICATIONS[:from_name]
      end
    end
  end # class Client
end # module BlackStack