# AirDrop Sync Feature - Setup Instructions

## Quick Setup Guide

Follow these steps to add the AirDrop sync feature to your Xcode project.

## Step 1: Add Files to Xcode Project

The following files have been created and need to be added to your Xcode project:

### Models
- `Models/SyncPackage.swift`

### Services
- `Services/ImportService.swift`

### Views
- `Views/SyncView.swift`
- `Views/ImportConfirmationView.swift`

### How to Add Files:

1. Open `MoleTracker.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), right-click on the **Models** folder
3. Select "Add Files to MoleTracker..."
4. Navigate to and select `Models/SyncPackage.swift`
5. Ensure "Copy items if needed" is **unchecked** (files are already in correct location)
6. Ensure "MoleTracker" target is **checked**
7. Click "Add"

8. Repeat for **Services** folder:
   - Add `Services/ImportService.swift`

9. Repeat for **Views** folder:
   - Add `Views/SyncView.swift`
   - Add `Views/ImportConfirmationView.swift`

## Step 2: Register File Type

Add support for `.moletracker` files so iOS knows to open them with your app.

1. In Xcode, select the **MoleTracker** project in the navigator
2. Select the **MoleTracker** target
3. Go to the **Info** tab
4. Expand **Document Types** section
5. Click the **+** button to add a new document type
6. Configure as follows:
   - **Name**: MoleTracker Sync Package
   - **Types**: `com.moletracker.sync-package`
   - **Extensions**: `moletracker`
   - **Role**: Editor
   - **Rank**: Owner

7. Expand **Exported Type Identifiers** section
8. Click the **+** button
9. Configure as follows:
   - **Description**: MoleTracker Sync Package
   - **Identifier**: `com.moletracker.sync-package`
   - **Conforms To**: `public.data`
   - **Extensions**: `moletracker`

## Step 3: Add Localization Strings

Add the following strings to `MoleTracker/Localizable.xcstrings`:

### English Strings to Add:

```json
"sync_menu_item": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Sync to Device"
      }
    }
  }
},
"sync_title": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Sync Data"
      }
    }
  }
},
"sync_date_picker_label": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Export data since"
      }
    }
  }
},
"sync_date_section_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Select Date"
      }
    }
  }
},
"sync_date_section_footer": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Only moles and images created or modified since this date will be exported."
      }
    }
  }
},
"sync_preview_button": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Preview Export"
      }
    }
  }
},
"sync_export_section_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Export"
      }
    }
  }
},
"sync_export_section_footer": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Preview what will be exported before sharing."
      }
    }
  }
},
"sync_stats_moles": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Moles"
      }
    }
  }
},
"sync_stats_images": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Images"
      }
    }
  }
},
"sync_stats_since": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Since"
      }
    }
  }
},
"sync_share_button": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Share via AirDrop"
      }
    }
  }
},
"sync_preview_section_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Export Preview"
      }
    }
  }
},
"sync_confirm_title": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Export Data?"
      }
    }
  }
},
"sync_confirm_button": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Export"
      }
    }
  }
},
"sync_exporting": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Preparing export..."
      }
    }
  }
},
"sync_no_data_error": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "No new data to export since the selected date."
      }
    }
  }
},
"sync_export_failed": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Failed to create export package. Please try again."
      }
    }
  }
},
"import_title": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Import Data"
      }
    }
  }
},
"import_loading": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Reading package..."
      }
    }
  }
},
"import_info_moles": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Moles"
      }
    }
  }
},
"import_info_images": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Images"
      }
    }
  }
},
"import_info_since": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Since"
      }
    }
  }
},
"import_info_exported": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Exported"
      }
    }
  }
},
"import_package_info_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Package Information"
      }
    }
  }
},
"import_info_duplicates": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Duplicate items will be skipped"
      }
    }
  }
},
"import_info_merge": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "New data will be merged with existing"
      }
    }
  }
},
"import_info_safe": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Your existing data will not be deleted"
      }
    }
  }
},
"import_behavior_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Import Behavior"
      }
    }
  }
},
"import_confirm_button": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Import Data"
      }
    }
  }
},
"import_success": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Import completed successfully"
      }
    }
  }
},
"import_no_new_data": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "No new data to import"
      }
    }
  }
},
"import_result_moles_imported": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Moles imported"
      }
    }
  }
},
"import_result_images_imported": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Images imported"
      }
    }
  }
},
"import_result_moles_skipped": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Moles skipped"
      }
    }
  }
},
"import_result_images_skipped": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Images skipped"
      }
    }
  }
},
"import_result_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Import Results"
      }
    }
  }
},
"import_errors_header": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Errors"
      }
    }
  }
},
"import_error_title": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Cannot Read Package"
      }
    }
  }
},
"import_error_message": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "The sync package could not be read. It may be corrupted or from an incompatible version."
      }
    }
  }
}
```

**Note**: You can add these strings directly in Xcode's String Catalog editor, or manually edit the `Localizable.xcstrings` file.

## Step 4: Build and Test

1. Build the project (⌘B)
2. Fix any remaining build errors
3. Run on device or simulator
4. Test the sync feature:
   - Create some moles with images
   - Go to Menu → "Sync to Device"
   - Select date and preview
   - Share via AirDrop to another device
   - Accept on receiving device
   - Verify import works correctly

## Troubleshooting

### "Cannot find 'ImportConfirmationView' in scope"
- Make sure you added all View files to the Xcode project
- Clean build folder (⇧⌘K) and rebuild

### "Cannot find 'SyncPackage' in scope"
- Make sure you added the Models/SyncPackage.swift file
- Check that it's included in the target

### Localization strings not showing
- Add all required strings to Localizable.xcstrings
- Or use the default values (they're included in the code)

### File type not recognized
- Make sure you registered the .moletracker file type in Info.plist
- Restart the device after installing

## Verification Checklist

- [ ] All 4 new files added to Xcode project
- [ ] Project builds without errors
- [ ] "Sync to Device" appears in menu
- [ ] Date picker works
- [ ] Export preview shows correct counts
- [ ] AirDrop share sheet appears
- [ ] Receiving device opens import dialog
- [ ] Import completes successfully
- [ ] Data appears in receiving device

## Next Steps

Once setup is complete, refer to `AIRDROP_SYNC_FEATURE.md` for:
- Complete feature documentation
- User guide
- Privacy details
- Testing checklist
- Troubleshooting guide