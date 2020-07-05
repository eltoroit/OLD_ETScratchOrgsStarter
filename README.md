![ELTOROIT Test Scratch Org](https://github.com/eltoroit/T1/workflows/ELTOROIT%20Test%20Scratch%20Org/badge.svg)

# The Perfect SFDX Starter Project For Any Scratch Orgs Development

<p align="center">
	<img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/HeaderImage.png?raw=true" alt="The Perfect SFDX Starter Project For Any Scratch Orgs Development" />
</p>

A lot of the work I do outside my day-to-day job is to build demos and share them with my students and with the world. For this particular use case, scratch orgs are fantastic! But every time I need a new demo, I have to start with an empty scratch org and make the same changes again and again. I decided to start a template with all the things that I need in a scratch org, and I am sharing it with you.

By the way, I also use this scratch org template when working on some projects for my day-to-day job, and it has been super-helpful. Once I have the base template, I import the existing metadata from a sandbox or production Org using the techniques explained in the [SFDX Developer Guide | Project Setup](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_workspace_setup.htm).

I am sharing with you the [repo](https://github.com/eltoroit/ETScratchOrgsStarter) for this base scratch org, but I want to explain some things that you will find useful.

<p align="center">
<a href="https://github.com/eltoroit/ETScratchOrgsStarter" target="_blank"><img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/RepoLink.png?raw=true" alt="The Perfect SFDX Starter Project For Any Scratch Orgs Development" /></a>
</p>

# Folders & Files

## Metadata Folders: ./Deploy and ./doNotDeploy

Before I explain the contents of these folders, we need to understand there are two types of metadata in a scratch org: First, we have the metadata that we are creating or changing. Second the metadata required for the first type.

When building a trigger, for example, we need the files for the trigger but we also need the files for the sObject.We must deploy all our work back to a sandbox or production server, and it gets stored in the **./deploy** folder. All the metadata that is needed to build the code, but that won't be deployed, is stored in the **./doNotDeploy** folder.

To make this work, we need to work with the **./sfdx-project.json** file. This folder tells SFDX how the metadata is organized, in particular, this setting:

```
"packageDirectories": [
	{
		"path": "deploy",
		"default": true
	},
	{
		"path": "doNotDeploy",
		"default": false
	}
]
```

Both folders get processed when pushing metadata to a scratch org. When doing a pull, SFDX puts the metadata in the default (**./deploy**) folder.

## Code Formatting (./.prettierrc)

The **./.prettierrc** file indicates how the code gets formatted. It specifies the maximum with for the code, and that we will be using tabs vs. spaces. I prefer tabs over spaces, but let's not pick up a fight over that!

<!--
<p align="center"><iframe src="https://www.youtube.com/embed/SsoOG6ZeyUI?wmode=transparent&amp;showinfo=0" width="560" height="315" frameborder="0" allowfullscreen="allowfullscreen"></iframe></p>
-->

<div align="center">
  <a href="https://www.youtube.com/watch?v=SsoOG6ZeyUI" target="_blank"><img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/TabsVsSpaces.png?raw=true" alt="Tabs vs. Spaces"></a>
</div>

## ./config/project-scratch-def.json

This file describes the definition of the scratch org that gets created. There are few things of interest here:

`hasSampleData: false`

If true, then sample data will be created. But I also learned that sample metadata gets also created, so be careful. There are custom fields that get created on standard objects like accounts, leads, etc.

`settings.mobileSettings.enableS1EncryptedStoragePref2: false`

Setting this flag to false (highly recommended for scratch orgs), the orgs will not use the cache for UI rendering. There is a checkbox is the setup menu (`Security | Session Settings | Caching`) called **Enable secure and persistent browser caching to improve performance** which users love to have checked, but developers want to have this unchecked! This setting sets it while creating the scratch org.

## ./.vscode/tasks.json

This file helps to push metadata by using the VS Code pre-defined builder. When the build operation starts (**⌘⇧B**), VS Code saves unsaved, and it executes the commands defined in this file. In our case, the metadata gets pushed to the scratch org.

# ./@ELTOROIT Folder

This folder contains two crucial pieces of a successful scratch org creation:

-   Creating the scratch org
-   Loading the data

## Creating the scratch Org (./@ELTOROIT/scripts/CreateOrg.sh)

This batch files executes the common tasks that need to be done when creating a scratch org, they are:

1.  Creating scratch Org (`sfdx force:org:create`)
2.  Opening scratch Org (`sfdx force:org:open`) **(optional)**
3.  Configure the new org **before** the metadata is loaded **(optional)**
4.  Load the metadata (`sfdx force:source:push`)
5.  Configure the new org **after** the metadata is loaded **(optional)**
6.  Assigning the permission set to your user (`sfdx force:user:permset:assign`) **(optional)**
7.  Executing Anonymous Apex (`sfdx force:apex:execute`) **(optional)**
8.  Loading the data (`sfdx ETCopyData:import`) **(optional)**
9.  Runing Apex tests (`sfdx force:apex:test:run`) **(optional)**
10. Generating and displaying a password for the new user (`sfdx force:user:password:generate`) **(optional)**

Not all these options are required, and they can be customized based on the variables at the top of the Bash batch script. Let's talk about some of the most important steps:

**#2 Opening scratch Org.** I have noticed that sometimes the orgs that get created do not get the My Domain adequately configured, and trying to open the scratch org does not work and takes you over to the standard login screen. This optional step opens the scratch Org and pauses the script until you verify the new scratch org opens and hit the **enter** key.

**#3 (#5) Configure the new org before (after) the metadata is loaded** Sometimes, you need to perform some manual configuration (the configuration does not have corresponding metadata) on the scratch org before (after) the metadata is pushed to the org. These settings pause the creation of the org and let you perform that manual configuration before continuing with the creation of the org.

**#7 Executing Anonymous Apex** Some configuration does not map to a metadata file. Still, we can code them in Apex, and we can execute that Apex while creating the scratch org in this optional step.

**#8 Loading the data** I am using ETCopyData to load data, see below for more information

**#9 Running Apex tests** This is useful if you are doing a CI/CD because the Apex tests run when the scratch org is created.

**#10 Generating and displaying a password for the new user** Sometimes, for example, if you want to use the Salesforce Mobile App or connect via APIs, you may need the username/password for the org. This last optional step generates that password.

**Warning:** I am a Mac developer, and this script was created and tested on a Mac, but it could be easily converted to run on Windows. Are there any volunteers for a pull request?

## Loading the data

As seen above, one of the last steps executed when creating a scratch org is to load the required data. We may have very complex data structures that are not easily loaded with the core SFDX commands provided. This repo uses the **ETCopyData** plugin I built. You can find it here: **[https://github.com/eltoroit/ETCopyData](https://github.com/eltoroit/ETCopyData)**

# Bonus content

## ./@ELTOROIT/scripts/DeleteOrgs.sh

One of the things I like to do with scratch Orgs is to create more scratch orgs than needed. This process helps me know the metadata I have in the repo is complete, and that I will be able to create a scratch org at any time. It also helps me prove the demos I am sharing with the world can work. This creates a ton of scratch Orgs, that need to be cleaned!

This script looks for scratch orgs that do not have an alias associated (I may have re-used the alias with a new scratch org) and deletes them.
