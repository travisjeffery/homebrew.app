#
#  AppDelegate.rb
#  Homebrew
#
#  Created by Travis Jeffery on 11-05-11.
#  Copyright 2011 Travis Jeffery. All rights reserved.
#
#  Notes: Yes, this is Ruby. But most of the methods, classes, and so forth
#  come from Apple's Frameworks written in Objective-C and it's style, and in
#  paticular, in camelCase. Thus, I've tried to maintain that style as much as
#  possible and you should to.

# should probably have a preference to save if in custom location

framework 'Foundation'

HOMEBREW_PATH = ENV['HOMEBREW_PATH'] || "/usr/local/bin/brew"

class AppDelegate
    attr_accessor :window
    attr_accessor :formulas
    attr_accessor :totalFormulasFoundLabel
    attr_accessor :segmentedControl
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
        @myGroup = Dispatch::Group.new
        @myQueue = Dispatch::Queue.new('com.travisjeffery.homebrew')
        
        emptyFormulas && @managedObjectContext.save(nil)
        
        storeFormulasWithFormulas(`#{HOMEBREW_PATH} search`.split)

        @managedObjectContext.save(nil)
        
        @totalFormulasFoundLabel.stringValue = "#{totalFormulasFoundWithRequest(nil, withPredicate:nil)} in total found"
    end
    
    def close(sender)
        window.close
    end
    
    def segmentedControlAction(sender)
        puts "segmentedControl clicked"
        case sender.cell.tagForSegment(sender.selectedSegment)
        when 1
            puts "selectedSegment was 1"
            installedFormulas(nil)
        when 2
            puts "selectedSegment was 2"
            outdatedFormulas(nil)
        else
            # all
            results = formulasFoundWithRequest(nil, withPredicate:nil)
            @totalFormulasFoundLabel.stringValue = "#{results.length} in total found"
        end
    end
    
    def installedFormulas(sender)
        results = formulasFoundWithRequest(nil, withPredicate:NSPredicate.predicateWithFormat("isInstalled == Ok"))
        @totalFormulasFoundLabel.stringValue = "#{results.length} in total found"
    end

    def outdatedFormulas(sender)
        emptyFormulas
        storeFormulasWithFormulas(`#{HOMEBREW_PATH} outdated`.split)
    end
    
    def emptyFormulas
        formulasFoundWithRequest(nil, withPredicate:nil).each do |result|
            @managedObjectContext.deleteObject(result)
        end 
    end

    def formulasFoundWithRequest(request, withPredicate:predicate)
        unless request
            request = NSFetchRequest.new
            request.entity = NSEntityDescription.entityForName("Formula", inManagedObjectContext:@managedObjectContext)
        end
        request.predicate = predicate if predicate
        error = Pointer.new(:id)

        @managedObjectContext.executeFetchRequest(request, error:error)
    end
    
    def totalFormulasFoundWithRequest(request, withPredicate:predicate)
        formulasFoundWithRequest(request, withPredicate:predicate).length
    end
    
    def storeFormulasWithFormulas(formulas)
        # until i have the caching working correctly, getting first small
        # amounts of formulas for speed purposes during development
        formulas[0..25].each do |formula|
            @myQueue.async(@myGroup) do
                info = `#{HOMEBREW_PATH} info #{formula}`.split
                # todo: add in comments section that this formula is outdated
                newFormula = NSEntityDescription.insertNewObjectForEntityForName("Formula", inManagedObjectContext: @managedObjectContext)

                # xxx: hackish
                newFormula.name     = info[0]
                newFormula.version  = info[1]
                #newFormula.homepage = NSString.hyperlinkFromString(info[2], info[2])
                newFormula.homepage  = info[2]
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
        error = Pointer.new(:id)

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
        error = Pointer.new(:id)

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

