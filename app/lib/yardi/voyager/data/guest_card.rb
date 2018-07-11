module Yardi
  module Voyager
    module Data
      class GuestCard
        require 'nokogiri'

        # REJECTED_CUSTOMER_TYPES = %w{guarantor cancelled other}
        ACCEPTED_CUSTOMER_TYPES = %w{applicant approved_applicant future_resident prospect}

        attr_accessor :debug,
          :name_prefix, :first_name, :middle_name, :last_name,
          :prospect_id, :tenant_id, :third_party_id, :property_id,
          :address1, :address2, :city, :state, :postalcode,
          :email,
          :phones,
          :expected_move_in, :lease_from, :lease_to,
          :actual_move_in, :floorplan, :unit, :rent, :bedrooms,
          :preference_comment,
          :events,
          :record_type

        def self.from_lead(lead, yardi_property_id)
          card = GuestCard.new
          card.name_prefix = lead.title
          card.first_name = lead.first_name
          card.last_name = lead.last_name
          card.prospect_id = lead.remoteid
          card.property_id = yardi_property_id
          card.email = lead.email
          card.phones = self.voyager_phones_from_lead(lead)
          card.expected_move_in = lead.preference.move_in.strftime("%Y-%m-%d")
          card.preference_comment = lead.preference.notes
          return card
        end

        def self.from_GetYardiGuestActivity(data)
          self.from_api_response(response: data, method: 'GetYardiGuestActivity_Login') do |response_data|
             response_data["LeadManagement"]["Prospects"]["Prospect"].
               map{|record| GuestCard.from_guestcard_node(record)}.flatten
          end
        end

        # Return [ Lead ] with an updated remoteid from Yardi Voyager
        def self.from_ImportYardiGuest(response:, lead:)
          self.from_api_response(response: response, method: 'ImportYardiGuest_Login') do |response_data|
            messages = response_data.fetch("Messages",false)
            if messages
              msgs = Array(messages["Message"]).map do |m|
                [m.fetch("messageType",'Default'), m.fetch("__content__", "Default")]
              end
              remoteid = msgs.map{|m| m[1].match(/CustomerID: ([a-z0-9]+)$/)[1] rescue nil}.compact.first
            end
            lead.remoteid = remoteid if remoteid.present?
            lead
          end
        end

        def self.from_api_response(response:, method:, &block)
          root_node = nil

          case response
          when String
            begin
              data = JSON(response)
            rescue => e
              raise Yardi::Voyager::Data::Error.new("Invalid GuestCard JSON: #{e}")
            end
          when Hash
            data = response
          else
            raise Yardi::Voyager::Data::Error.new("Invalid GuestCard data. Should be JSON string or Hash")
          end

          begin
            # Handle Server Error
            if data["Envelope"]["Body"].fetch("Fault", false)
              err_msg = data["Envelope"]["Body"]["Fault"].to_s
              raise Yardi::Voyager::Data::Error.new(err_msg)
            end
            root_node = data["Envelope"]["Body"]["#{method}Response"]["#{method}Result"]
            messages = root_node.fetch("Messages",false)
            if messages
              msgs = Array(messages["Message"]).map do |m|
                [m.fetch("messageType",'Default'), m.fetch("__content__", "Unknown error")].join(': ')
              end
              msg = msgs.join(';')
              Rails.logger.warn("Yardi::Voyager API Messages: #{msg}")
            end
          rescue => e
            raise Yardi::Voyager::Data::Error.new("Invalid GuestCard data schema: #{e}")
          end

          return yield(root_node)
        end

        def self.from_guestcard_node(data)
          prospects = []
          prospect_record = data['Customers']['Customer']
          prospect_preferences = data['CustomerPreferences']
          prospect_events = data['Events']

          [ prospect_record ].flatten.compact.each do |pr|
            # Abort processing if this is not a wanted Customer type
            record_type = pr['Type']
            next if !ACCEPTED_CUSTOMER_TYPES.include?(record_type)

            prospect = GuestCard.new
            prospect.record_type = record_type

            pr['Identification'].tap do |identification|
              ( identification ).each do |ident|
                val = ident['IDValue']
                case ident['IDType']
                when 'ProspectID'
                  prospect.prospect_id = val
                when 'TenantID'
                  prospect.tenant_id = val
                when 'PropertyID'
                  prospect.property_id = val
                when 'ThirdPartyID'
                  prospect.third_party_id = val
                end
              end
            end if pr['Identification']

            pr['Name'].tap do |name|
              prospect.name_prefix = name['NamePrefix']
              prospect.first_name = name['FirstName']
              prospect.middle_name = name['MiddleName']
              prospect.last_name = name['LastName']
            end if pr['Name']
            pr['Address'].tap do |address|
              prospect.address1 = address['AddressLine1']
              prospect.address2 = address['AddressLine2']
              prospect.city = address['City']
              prospect.state = address['State']
              prospect.postalcode = address['PostalCode']
            end if pr['Address']

            pr['Phone'].tap do |phones|
              prospect.phones = [ phones ].flatten.map do |phone|
                [ phone['PhoneType'], phone['PhoneNumber'] ]
              end
            end if pr['Phone']

            prospect.email = pr['Email']
            pr['Lease'].tap do |lease|
              prospect.expected_move_in = ( Date.parse(lease['ExpectedMoveInDate']) rescue nil)
              prospect.lease_from = ( Date.parse(lease['LeaseFromDate']) rescue nil)
              prospect.lease_to = ( Date.parse(lease['LeaseToDate']) rescue nil)
              prospect.actual_move_in =( Date.parse(lease['ActualMoveIn']) rescue nil)
              prospect.rent = ( lease['CurrentRent'] || 1 ).to_i
            end if pr['Lease']
            prospect.expected_move_in ||= prospect_preferences['TargetMoveInDate']
            prospect.floorplan = prospect_preferences['DesiredFloorplan']
            prospect_preferences['DesiredUnit'].tap do |unit|
              prospect.unit = (unit['MarketingName']) rescue nil
            end if prospect_preferences['DesiredUnit']
            prospect_preferences['DesiredRent'].tap do |rent|
              prospect.rent = rent['Exact'].to_i
            end if prospect_preferences['DesiredRent']
            prospect_preferences['DesiredNumBedrooms'].tap do |bedrooms|
              prospect.bedrooms = ( bedrooms['Exact'] || 1 ).to_i
            end if prospect_preferences['DesiredNumBedrooms']
            prospect_preferences['Comment'].tap do |comment|
              prospect.preference_comment = ([ comment ] || []).flatten.compact.join(' ')
            end if prospect_preferences['Comment']

            if (events = prospect_events.try(:first).try(:last))
              prospect.events = [ events ].flatten.compact.map{|e| "%s %s: %s" % [e["EventType"], e["EventDate"], e["Comments"]] }
            end

            prospects << prospect
          end

          return prospects
        end

        def self.to_xml(lead:, propertyid:)
          organization = Yardi::Voyager::Api::Configuration.new.vendorname
          agent = lead.user ||
                  lead.property.primary_agent ||
                  User.new(first_name: 'None', last_name: 'None')
          customer = GuestCard.from_lead(lead, propertyid)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.LeadManagement('xmlns' => '') {
              xml.Prospects {
                xml.Prospect {
                  xml.Customers {
                    xml.Customer('Type' => 'prospect') {
                      if lead.remoteid.present?
                        xml.Identification('IDType' => 'ProspectID', 'IDValue' => lead.remoteid)
                      end
                      xml.Identification('IDType' => 'ThirdPartyID', 'IDValue' => lead.shortid, 'OrganizationName' => organization)
                      xml.Identification('IDType' => 'PropertyID', 'IDValue' => propertyid, 'OrganizationName' => 'Yardi')
                      xml.Identification('IDType' => 'NoMiddleName', 'IDValue' => 'true')
                      xml.Name {
												xml.NamePrefix customer.name_prefix
												#xml.MiddleName
                        xml.FirstName customer.first_name || ' '
                        xml.LastName customer.last_name || ' '
                      }
											#xml.Address('AddressType' => 'current') {
												#xml.AddressLine1
												#xml.AddressLine2
												#xml.City
												#xml.State
												#xml.PostalCode
											#}
                      customer.phones.compact.each do |phone|
                        if phone.first.present?
                          xml.Phone('PhoneType' => phone[0]) {
														xml.PhoneNumber phone[1]
                          }
                        end
                      end
                      xml.Email customer.email
                      if customer.expected_move_in.present? &&
                        customer.expected_move_in > ( lead.first_comm + 1.week )
                        xml.Lease {
                          xml.ExpectedMoveInDate customer.expected_move_in
                        }
                      end
                    }
                  }
                  xml.CustomerPreferences {
                    if customer.expected_move_in.present? &&
                      customer.expected_move_in > ( lead.first_comm + 1.week )
                        xml.TargetMoveInDate customer.expected_move_in
                    end
                    if ( lead.preference.try(:beds) || 0 ) > 0
                      xml.DesiredNumBedrooms('Exact' => lead.preference.beds.to_i.to_s)
                    end
                    if ( lead.preference.try(:baths) || 0 ) > 0
                      xml.DesiredNumBathrooms('Exact' => lead.preference.baths.round.to_s)
                    end

                    # Voyager doesn't like DesiredRent elements for some reason
                    #
                    #if (lead.preference.try(:max_price) || 0) > 0
                      #xml.DesiredRent('Exact' => lead.preference.max_price.to_s)
                    #end

                    # Voyager doesn't like DesiredFloorplan elements for some reason
                    #
                    #if lead.preference.unit_type.present? && lead.preference.unit_type.remoteid.present?
                      #xml.DesiredFloorplan lead.preference.unit_type.name
                    #end
                  }
                  unless lead.remoteid.present?
                    # New GuestCards in Voyager must provide at least one Event record.
                    xml.Events {
                      xml.Event('EventType' => 'Other', 'EventDate' => lead.first_comm.strftime("%FT%T") ) {
                        xml.EventID('IDValue' => '')
                        xml.Agent {
                          xml.AgentName {
                            xml.FirstName agent.first_name
                            xml.LastName agent.last_name
                          }
                        }
                        xml.EventReasons 'Spoke to'
                        xml.FirstContact 'true'
                        xml.Comments("%s (Druid Lead from %s/%s)" % [lead.preference.notes, lead.source.try(:name), lead.referral])
                        xml.TransactionSource 'Referral'
                      }
                    }
                  end
                }
              }
            }
          end

          # Return XML without XML doctype or carriage returns
          return builder.doc.root.serialize(save_with:0)
        end

        def self.voyager_phones_from_lead(lead)
          phones = { office: nil, cell: nil, home: nil, fax: nil }
          convert_phone_type = lambda { |phone_type|
            case phone_type
            when 'Cell'
              'cell'
            when 'Home'
              'home'
            when 'Work'
              'office'
            else
              'home'
            end
          }
          [[lead.phone1, lead.phone1_type],[lead.phone2, lead.phone2_type]].each do |phone|
            pn, pt = phone
            case pt
            when 'Cell'
              phones[:cell] = pn
            when 'Home'
              phones[:home] = pn
            when 'Work'
              phones[:office] = pn
            end
          end
          phones[:office] ||= ( phones[:home] || phones[:cell] )
          phones[:cell] ||= (phones[:home] || phones[:office])
          return phones.to_a
        end

        def summary
          <<~EOS
            == Yardi Voyager GuestCard ==
            * Type: #{@record_type}
            * Name: #{@name_prefix} #{@first_name} #{@middle_name} #{@last_name}
            * Address: #{@address1} #{@address2} #{@city}, #{@state} #{@postalcode}
            * Phones: #{@phones.inspect}
            * Property ID: #{@property_id}
            * Prospect ID: #{@prospect_id}
            * Tenant ID: #{@tenant_id}
            * Third Party ID: #{@third_party_id}
            * Preferences:
              - Expected Move In: #{@expected_move_in}
              - Lease From:       #{@lease_from}
              - Lease To:         #{@lease_to}
              - Actual Move In:   #{@actual_move_in}
              - FloorPlan:        #{@flooplan}
              - Unit:             #{@unit}
              - Rent:             #{@rent}
              - Bedrooms:         #{@bedrooms}
            * Comment: #{@preference_comment}
            * Events: #{@events.inspect}
          EOS
        end


      end
    end
  end
end
