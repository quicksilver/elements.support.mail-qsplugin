Quicksilver E-mail Support
==========================

This plug-in depends on the [MailCore framework](https://github.com/mronge/MailCore). It's already included as a sub-project for this plug-in. After checking out this project, make sure to run:

    git submodule update --init --recursive

Now, you should be able to come back to this project and build.

Building Other Mail Plugins that Rely on MailCore/QSMailMediator.h
------------------------------------------------------------------

If you plan on building other plugins that require either MailCore or the QSMailMediator.h file, make sure to add both to the 'Header Search Paths' build setting of your new plugin. To do this follow the steps below (this assumes you have an Xcode project called 'MyPlugin.xcodeproj'):

1. Create your new plugin in the same root folder as the `elements.support.mail-qsplugin` folder. **Important**: do not rename the Email-Support folder from `elements.support.mail-qsplugin`
2. Go to your plugin's build0settings by clicking the 'MyPlugin' icon in the sidebar, then clicking your plugin's target, and clicking 'Build Settings'
3. Search for `header search paths` in the searchbar
4. Find the 'Header Search Paths' setting. Open the text by double clicking the item
5. Enter the text: `"$(SRCROOT)/../elements.support.mail-qsplugin"`
6. Enter the text: `elements.support.mail-qsplugin/MailCore/build-mac/build/$(CONFIGURATION)/include`

Here's a screenshot of how your configuration should look:

![Header Search Paths](header-search-paths.png)

Before You Try It Out
---------------------

Before trying out any of these plugins, it's always a good idea to **BACKUP** all of your Quicksilver data.

This is easily done by backing up the following folders 

(`<user>` stands for your short user name):

`/Users/<user>/Library/Application Support/Quicksilver`  
`/Users/<user>/Library/Caches/Quicksilver`

	
Before Building
---------------

Quicksilver must be built from source. See the QSApp.com wiki for more information on [Building Quicksilver](http://qsapp.com/wiki/Building_Quicksilver).

Also check out the [Quicksilver Plugins Development Reference](http://projects.skurfer.com/QuicksilverPlug-inReference.mdown).

Legal Stuff 
-----------

By downloading and/or using this software you agree to the following terms of use:

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this software except in compliance with the License.
    You may obtain a copy of the License at
    
      http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


Which basically means: whatever you do, I can't be held accountable if something breaks.