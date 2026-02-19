<!--
template: page-with-child-list
-->
# Automatic importers

If you use the automatic importer flow, any `*.ase` or `*.aseprite` file saved in the project folder will be automatically imported as a resource.

You can choose which importer to use via the Import dock. By default, Aseprite files will use the "No import" option, which will show them in the filesytem dock, but won't generate any resources. You can change the default importer behaviour via Project Settings.

By default, you will need Aseprite installed on every machine working on your project, as only the source files are included in the version control. If you need to work on your project on machines without Aseprite, you might want to enable the baking feature.

## Baking

> Baking is a new feature. It works, but might require extra polishing and UX improvements. Feel free to send your feedback and suggestions in the plugin's repository.

When the "Generate baking files" option is enabled in the project settings, the plugin will create a "bake" file alongside the source file. This bake file is the same resource built by the importer and will be used as a fallback when Aseprite is not configured in the machine.

You might want to enable bake files when:

- You intend to open and build your project on machines that don't have Aseprite installed
- Your project uses continuous integration to automate your game build, and you don't want to build Aseprite from source in your pipeline as this might take a long time and resources
- You want to make sure you can build your project in the future even if you stop using Aseprite

One thing to consider when enabling baking is that the bake files now become part of your project and should be included in your version control. This means potentially more noise when actively working on animations and also an increase in the project source size. As we are talking about pixel art this won't be a huge increase, but something to keep in mind nonetheless.

As for the exported project, there should be no difference on the exported game size, as the plugin makes sure to only include one version of the file (either the one in the import folder or the bake file when that's not present).

-----
