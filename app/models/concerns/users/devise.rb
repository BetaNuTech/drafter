module Users
  module Devise
    extend ActiveSupport::Concern

    included do
      devise :database_authenticatable, :registerable,
             :recoverable, :rememberable, :validatable,
             :trackable, :confirmable, :lockable
      #def send_devise_notification(notification, *args)
        #devise_mailer.send(notification, self, *args).deliver_later
      #end

      def password_required?
        confirmed? ? super : false
      end
    end

  end
end
