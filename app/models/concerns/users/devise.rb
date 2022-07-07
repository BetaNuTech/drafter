module Users
  module Devise
    extend ActiveSupport::Concern

    included do
      devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :confirmable, :lockable
      #def send_devise_notification(notification, *args)
        #devise_mailer.send(notification, self, *args).deliver_later
      #end

      def password_required?
        confirmed? ? super : false
      end

      def active_for_authentication?
        super && !deactivated?
      end
    end

  end
end
