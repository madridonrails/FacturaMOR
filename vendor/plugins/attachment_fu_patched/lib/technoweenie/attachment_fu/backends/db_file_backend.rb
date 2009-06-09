module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Backends
      # Methods for DB backed attachments
      module DbFileBackend
        def self.included(base) #:nodoc:
          Object.const_set(:DbFile, Class.new(ActiveRecord::Base)) unless Object.const_defined?(:DbFile)
          base.belongs_to  :db_file, :class_name => '::DbFile', :foreign_key => 'db_file_id'
        end

        # added by fxn, taken from http://deadprogrammersociety.blogspot.com/2007/04/getting-your-attachmentfu-back-out-of.html
        def image_data(thumbnail = nil)
          if thumbnail.nil?
            current_data
          else
            thumbnails.find_by_thumbnail(thumbnail.to_s).current_data
          end
        end

        # Creates a temp file with the current db data, added thumbnail parameter by fxn.
        def create_temp_file(thumbnail = nil)
          write_to_temp_file image_data(thumbnail)
          # write_to_temp_file current_data
        end
        
        # Gets the current data from the database
        def current_data
          db_file.data
        end
        
        protected
          # Destroys the file.  Called in the after_destroy callback
          def destroy_file
            db_file.destroy if db_file
          end
          
          # Saves the data to the DbFile model
          def save_to_storage
            if save_attachment?
              (db_file || build_db_file).data = temp_data
              db_file.save!
              self.class.update_all ['db_file_id = ?', self.db_file_id = db_file.id], ['id = ?', id]
            end
            true
          end
      end
    end
  end
end