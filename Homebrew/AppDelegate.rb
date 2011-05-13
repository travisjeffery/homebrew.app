#
#  AppDelegate.rb
#  Homebrew
#
#  Created by Travis Jeffery on 11-05-11.
#  Copyright 2011 Travis Jeffery. All rights reserved.
#

# should probably have a preference to save if in custom location
HOMEBREW_PATH = "/usr/local/bin/brew"

class AppDelegate
    attr_accessor :window
    attr_accessor :formulas
    attr_accessor :totalFormulasFoundLabel
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
        @myGroup = Dispatch::Group.new
        @myQueue = Dispatch::Queue.new('com.travisjeffery.homebrew')
        
        emptyFormulas && @managedObjectContext.save(nil)
        
        storeFormulasWithFormulas(`#{HOMEBREW_PATH} search`.split)

        @managedObjectContext.save(nil)
        
        @totalFormulasFoundLabel.stringValue = "#{totalFormulasFound} in total found"
    end
    
    def close(sender)
        window.close
    end
    
    def emptyFormulas
        allFormulas = NSFetchRequest.alloc.init
        allFormulas.setEntity(NSEntityDescription.entityForName("Formula", inManagedObjectContext:@managedObjectContext))
        formulas = @managedObjectContext.executeFetchRequest(allFormulas, error:nil)
        formulas.each do |formula|
            @managedObjectContext.deleteObject(formula)
        end 
    end
    
    def totalFormulasFound
        allFormulas = NSFetchRequest.alloc.init
        allFormulas.setEntity(NSEntityDescription.entityForName("Formula", inManagedObjectContext:@managedObjectContext))
        @managedObjectContext.executeFetchRequest(allFormulas, error:nil).length
    end
    
    def storeFormulasWithFormulas(formulas)
        formulas[0..5].each do |formula|
            @myQueue.async(@myGroup) do
                info = `#{HOMEBREW_PATH} info #{formula}`.split
                # todo: add in comments section that this formula is outdated
                newFormula = NSEntityDescription.insertNewObjectForEntityForName("Formula", inManagedObjectContext: @managedObjectContext)
                newFormula.name = info[0]
                newFormula.version = info[1]
                newFormula.homepage = info[2]
                # todo: check if formula is old
                newFormula.isInstalled = "Ok" if `#{HOMEBREW_PATH} info #{formula}`.scan(/Not installed/).empty?
            end
        end
        @myGroup.wait
    end
    
    def awakeFromNib
    end

    # Persistence accessors
    attr_reader :persistentStoreCoordinator
    attr_reader :managedObjectModel
    attr_reader :managedObjectContext

    #
    # Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Homebrew" in the user's Library directory.
    #
    def applicationFilesDirectory
        file_manager = NSFileManager.defaultManager
        library_url = file_manager.URLsForDirectory(NSLibraryDirectory, inDomains:NSUserDomainMask).lastObject
        library_url.URLByAppendingPathComponent("Homebrew")
    end

    #
    # Creates if necessary and returns the managed object model for the application.
    #
    def managedObjectModel
        unless @managedObjectModel
          model_url = NSBundle.mainBundle.URLForResource("Homebrew", withExtension:"momd")
          @managedObjectModel = NSManagedObjectModel.alloc.initWithContentsOfURL(model_url)
        end
        
        @managedObjectModel
    end

    #
    # Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    #
    def persistentStoreCoordinator
        return @persistentStoreCoordinator if @persistentStoreCoordinator

        mom = self.managedObjectModel
        unless mom
            puts "#{self.class} No model to generate a store from"
            return nil
        end

        file_manager = NSFileManager.defaultManager
        directory = self.applicationFilesDirectory
        error = Pointer.new_with_type('@')

        properties = directory.resourceValuesForKeys([NSURLIsDirectoryKey], error:error)

        if properties.nil?
            ok = false
            if error[0].code == NSFileReadNoSuchFileError
                ok = file_manager.createDirectoryAtPath(directory.path, withIntermediateDirectories:true, attributes:nil, error:error)
            end
            if ok == false
                NSApplication.sharedApplication.presentError(error[0])
            end
        elsif properties[NSURLIsDirectoryKey] != true
                # Customize and localize this error.
                failure_description = "Expected a folder to store application data, found a file (#{directory.path})."

                error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:101, userInfo:{NSLocalizedDescriptionKey => failure_description})

                NSApplication.sharedApplication.presentError(error)
                return nil
        end

        url = directory.URLByAppendingPathComponent("Homebrew.storedata")
        @persistentStoreCoordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(mom)

        unless @persistentStoreCoordinator.addPersistentStoreWithType(NSXMLStoreType, configuration:nil, URL:url, options:nil, error:error)
            NSApplication.sharedApplication.presentError(error[0])
            return nil
        end

        @persistentStoreCoordinator
    end

    #
    # Returns the managed object context for the application (which is already
    # bound to the persistent store coordinator for the application.) 
    #
    def managedObjectContext
        return @managedObjectContext if @managedObjectContext
        coordinator = self.persistentStoreCoordinator

        unless coordinator
            dict = {
                NSLocalizedDescriptionKey => "Failed to initialize the store",
                NSLocalizedFailureReasonErrorKey => "There was an error building up the data file."
            }
            error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:9999, userInfo:dict)
            NSApplication.sharedApplication.presentError(error)
            return nil
        end

        @managedObjectContext = NSManagedObjectContext.alloc.init
        @managedObjectContext.setPersistentStoreCoordinator(coordinator)

        @managedObjectContext
    end

    #
    # Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    #
    def windowWillReturnUndoManager(window)
        self.managedObjectContext.undoManager
    end

    #
    # Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    #
    def saveAction(sender)
        error = Pointer.new_with_type('@')

        unless self.managedObjectContext.commitEditing
          puts "#{self.class} unable to commit editing before saving"
        end

        unless self.managedObjectContext.save(error)
            NSApplication.sharedApplication.presentError(error[0])
        end
    end

    def applicationShouldTerminate(sender)
        # Save changes in the application's managed object context before the application terminates.

        return NSTerminateNow unless @managedObjectContext

        unless self.managedObjectContext.commitEditing
            puts "%@ unable to commit editing to terminate" % self.class
        end

        unless self.managedObjectContext.hasChanges
            return NSTerminateNow
        end

        error = Pointer.new_with_type('@')
        unless self.managedObjectContext.save(error)
            # Customize this code block to include application-specific recovery steps.
            return NSTerminateCancel if sender.presentError(error[0])

            alert = NSAlert.alloc.init
            alert.messageText = "Could not save changes while quitting. Quit anyway?"
            alert.informativeText = "Quitting now will lose any changes you have made since the last successful save"
            alert.addButtonWithTitle "Quit anyway"
            alert.addButtonWithTitle "Cancel"

            answer = alert.runModal
            return NSTerminateCancel if answer == NSAlertAlternateReturn
        end

        NSTerminateNow
    end
end

