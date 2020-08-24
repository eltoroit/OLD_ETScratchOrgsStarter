![ELTOROIT Test Scratch Org](https://github.com/eltoroit/ETScratchOrgsStarter/workflows/ELTOROIT%20Test%20Scratch%20Org/badge.svg)

# The Perfect SFDX Starter Project For Any Scratch Orgs Development

<p align="center">
	<img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/HeaderImage.png?raw=true" alt="The Perfect SFDX Starter Project For Any Scratch Orgs Development" />
</p>

**I love scratch ORGs!** But setting them up can be time-consuming, so I created this template. I have found myself using this template anytime I need to create a scratch org for POC (proof-of-concept), demos, or when I need to start a new project.

This template contains all the core things that you will need in a scratch org, including scripts for setting up CI/CD. I am using GitHub Actions, but you could easily adjust it to other tools. I have been using it a lot, and I love it, **so I decided to share it with you!**

Once I have the base template, I import the existing metadata from a sandbox or production Org using the techniques explained in the [SFDX Developer Guide | Project Setup](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_workspace_setup.htm).

I am sharing with you the [repo](https://github.com/eltoroit/ETScratchOrgsStarter) for this base scratch org, but I want to explain some things that you will find useful.

<p align="center">
<a href="https://github.com/eltoroit/ETScratchOrgsStarter" target="_blank"><img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/RepoLink.png?raw=true" alt="The Perfect SFDX Starter Project For Any Scratch Orgs Development" /></a>
</p>

# Folders & Files

## Metadata Folders: ./Deploy and ./doNotDeploy

Before I explain the contents of these folders, we need to understand there are two types of metadata in a scratch org: First, we have the metadata that we are creating or changing and that we will need to eventually deploy to sandboxes or production. The second type of metadata is the one required for the first type ;-)

Let's suppose you are building a trigger for an existing sObject. In this case, we need the metadata for the trigger itself (which will need to deploy), but we also need the metadata for the sObject, fields, page layouts, list views, profiles, permission sets, etc (which we do not want to deploy). When it's time to deploy all our work back to a sandbox or production server, we need to easily identify the metadata, but with this sturucture is quite easy becase it's located in the **./deploy** folder. All the other metadata that is needed to build the code, but that won't be deployed, is stored in the **./doNotDeploy** folder.

To make this work, we need to work with the **./sfdx-project.json** file. This file tells SFDX how the metadata is organized, in particular, this setting:

```
"packageDirectories": [
	{
		"path": "doNotDeploy",
		"default": false
	},
	{
		"path": "deploy",
		"default": true
	}
]
```

Both folders get processed when pushing metadata to a scratch org. When doing a pull, SFDX puts the new metadata in the default (**./deploy**) folder.

## Code Formatting (./.prettierrc)

The **./.prettierrc** file indicates how the code gets formatted. It specifies the maximum with for the code, and that we will be using tabs vs. spaces. I prefer tabs over spaces, but let's not pick up a fight over that!

<div align="center">
  <a href="https://www.youtube.com/watch?v=SsoOG6ZeyUI" target="_blank"><img src="https://github.com/eltoroit/ETScratchOrgsStarter/blob/blog/@ELTOROIT/blog/TabsVsSpaces.png?raw=true" alt="Tabs vs. Spaces"></a>
</div>

## ./config/project-scratch-def.json

This file describes the definition of the scratch org that gets created. There are few things of interest here:

`hasSampleData: false`

If true, then sample data will be created. But I also learned that sample **metadata** gets also created, so be careful. There are custom fields that get created on standard objects like accounts, leads, etc which you may not want.

`settings.mobileSettings.enableS1EncryptedStoragePref2: false`

Setting this flag to false (highly recommended for scratch orgs), the orgs will not use the cache for UI rendering. There is a checkbox is the setup menu (`Security | Session Settings | Caching`) called **Enable secure and persistent browser caching to improve performance** which users love to have checked, but developers want to have this unchecked! This setting sets it while creating the scratch org.

## ./.vscode/tasks.json

This file helps to push metadata by using the VS Code pre-defined builder. When the build operation starts (**⌘⇧B**), VS Code saves unsaved, and it executes the commands defined in this file. In our case, the metadata gets pushed to the scratch org.

# ./@ELTOROIT Folder

This folder contains two crucial pieces of a successful scratch org creation:

-   The data to populate a scratch org
-   The scripts to create the scratch org

## Creating the scratch Org (./@ELTOROIT/scripts/shell/CreateOrg.sh)

This batch files executes the common tasks that need to be done when creating a scratch org, they are:

| Operation                     | Switch<sup>[1](#FNF01)</sup>           | Description                                                             | Command                                      |
| ----------------------------- | -------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------- |
| **mainRunJest**               | RUN_JEST_TESTS                         | Run Jest tests<sup>[2](#FNF02)</sup>                                    | `npm run test:unit:coverage`                 |
| **mainBackupAlias**           | BACKUP_ALIAS                           | Backup the alias<sup>[3](#FNF03)</sup>                                  | `sfdx force:alias:set $ALIAS.bak=`           |
| **mainCreateScratchOrg**      | **Required**                           | Create scratch Org                                                      | `sfdx force:org:create`                      |
| **mainPauseToCheck**          | PAUSE2CHECK_ORG                        | Open scratch Org<sup>[4](#FNF04)</sup>                                  | `sfdx force:org:open`                        |
| **mainOpenDeployPage**        | SHOW_DEPLOY_PAGE<sup>[5](#FNF05)</sup> | Open the deploy page in the Org<sup>[6](#FNF06)</sup>                   | `sfdx force:org:open`                        |
| **mainManualMetadataBefore**  | PATH2SETUP_METADATA_BEFORE             | Manually configure **before metadata** is loaded<sup>[7](#FNF07)</sup>  | `sfdx force:org:open`                        |
| **mainExecuteApexBeforePush** | EXEC_ANON_APEX_BEFORE_PUSH             | Execute Apex code **before metadata** is loaded<sup>[8](#FNF08)</sup>   | `sfdx force:apex:execute`                    |
| **mainInstallPackages**       | PACKAGES<sup>[9](#FNF09)</sup>         | Install one or more packages                                            | `sfdx force:package:install`                 |
| **mainDeploy**                | PERFORM_DEPLOY                         | Deploy the metadata                                                     | `sfdx force:source:deploy`                   |
| **mainPushMetadata**          | **Required**                           | Push the metadata                                                       | `sfdx force:source:push`                     |
| **mainManualMetadataAfter**   | PATH2SETUP_METADATA_AFTER              | Manually configure **after metadata** is loaded<sup>[7](#FNF07)</sup>   | `sfdx force:org:open`                        |
| **mainExecuteApexAfterPush**  | EXEC_ANON_APEX_AFTER_PUSH              | Execute Apex code **after metadata** is loaded<sup>[8](#FNF08)</sup>    | `sfdx force:apex:execute`                    |
| **mainAssignPermissionSet**   | PERM_SET                               | Assign the permission set to your user                                  | `sfdx force:user:permset:assign`             |
| **mainDeployAdminProfile**    | ADMIN_PROFILE                          | Deploy the Admin profile<sup>[10](#FNF10)</sup>                         | `sfdx force:source:deploy`                   |
| **mainLoadData**              | IMPORT_DATA                            | Load the data using the ETCopydata plugin<sup>[11](#FNF11)</sup>        | `sfdx ETCopyData:import`                     |
| **mainExecuteApexAfterData**  | EXEC_ANON_APEX_AFTER_DATA              | Execute Anonymous Apex **after data** is loaded<sup>[8](#FNF08)</sup>   | `sfdx force:apex:execute`                    |
| **mainRunApexTests**          | RUN_APEX_TESTS                         | Runing Apex tests<sup>[12](#FNF12)</sup>                                | `sfdx force:apex:test:run`                   |
| **mainPushAgain**             | **Required**                           | Push the metadata again.<sup>[13](#FNF13)</sup>                         | `sfdx force:source:push`                     |
| **mainReassignAlias**         | **Required**                           | Assign the new scratch org to the desired alias                         | `sfdx sfdx force:config:set defaultusername` |
| **mainGeneratePassword**      | GENERATE_PASSWORD                      | Generate and display a password for the new user<sup>[14](#FNF14)</sup> | `sfdx force:user:password:generate`          |
| **QuitSuccess**               |                                        | Display a message indicating the process is complete                    |                                              |

# Footnotes
<a name="FNF01">1</a>: These switches are configured on the *CreateOrg.sh* file

<a name="FNF02">2</a>: Before the scratch org is created and the metadata/data is loaded, the Jest tests are executed.

<a name="FNF03">3</a>: Helps accessing the previous scratch org easily. Althought SFDX does not remove the old scratch org, it drops the alias and it's hard to recognize the previous org when one gets created.

<a name="FNF04">4</a>: I have noticed that sometimes the orgs that get created do not get the My Domain adequately configured, and trying to open the scratch org does not work and takes you over to the standard login screen. This optional step opens the scratch Org and pauses the script until you verify the new scratch org opens and hit the **enter** key.

<a name="FNF05">5</a>: There are actually two variables used here. The switch **SHOW_DEPLOY_PAGE** controls if the deploy status page is opened or not, and **DEPLOY_PAGE** is the URL for the actual page to open. This last one is set in **functions.sh**.

<a name="FNF06">6</a>: This allows you to monitor the installation progress

<a name="FNF07">7</a>: This opens a specific URL to allow you configuring manually something that can't be saved as metadata. Sometimes, you need to perform some manual configuration (the configuration does not have corresponding metadata) on the scratch org before (or after) the metadata is pushed to the org. These settings pause the creation of the org and let you perform that manual configuration before continuing with the creation of the org.

<a name="FNF08">8</a>: Some configuration does not map to a metadata file. Still, we can code them in Apex, and we can execute that Apex while creating the scratch org in this optional step. Maybe this is because the Apex code needs to be done once the metadata is loaded (assigning profiles, roles, ...) or after the data is loaded.

<a name="FNF09">9</a>: This is a list of package Ids to be installed. The switch must be set as a shell array like this: *PACKAGES=("04tB0000000P1yA" "04tB0000000P1yB" "04tB0000000P1yC")*

<a name="FNF10">10</a>: Hides the standard applications on the App Launcher, making it easier to work with your scratch org if you are creatina a custom app or even working with a standard app.

<a name="FNF11">11</a>: I am using ETCopyData to load data. We may have very complex data structures that are not easily loaded with the core SFDX commands provided. This repo uses the **ETCopyData** plugin I built. You can find it here: **[https://github.com/eltoroit/ETCopyData](https://github.com/eltoroit/ETCopyData)**

<a name="FNF12">12</a>: This is useful if you are doing a CI/CD because the Apex tests run when the scratch org is created.

<a name="FNF13">13</a>: I have seen in the latest CLI that conflicts do occur the first times the metadata gets pushed, pushing the metadata here helps "prevent" that.

<a name="FNF14">14</a>: Sometimes, for example, if you want to use the Salesforce Mobile App or connect via APIs, you may need the username/password for the org. This last optional step generates that password.

As indicated in the table above, not all these operations are required, and they can be customized based on the variables at the **CreateOrg.sh** script. You could also invoke each of these commands separately *./@ELTOROIT/scripts/shell/CreateOrg.sh mainRunJest*

The separation helps when you configure a CI/CD tool, I am using GitHub Actions and this is what my YAML file looks like:

```
name: "ELTOROIT Test Scratch Org"
on: [push]
jobs:
    create_org:
        runs-on: ubuntu-latest
        env:
            ET_CICD: true
        steps:
            - uses: actions/checkout@v2
            - name: Create etLogs folder as needed
              run: mkdir -p etLogs
            - name: PWD
              run: pwd
              if: ${{ env.ET_CICD  }}
            - name: Export token
              run: echo ${{ secrets.DEVHUB_TOKEN}} > etLogs/token.txt
            - name: Install tools
              run: |
                  wget https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-amd64.tar.xz
                  mkdir sfdx-cli
                  tar xJf sfdx-linux-amd64.tar.xz -C sfdx-cli --strip-components 1
                  ./sfdx-cli/install
                  sfdx force:lightning:lwc:test:setup
                  echo 'y' | sfdx plugins:install etcopydata@beta
            - name: Register DevHub
              run: sfdx force:auth:sfdxurl:store -f etLogs/token.txt --setalias DevHub --setdefaultdevhubusername
            - name: Run Jest
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainRunJest
            - name: Create Scratch Org
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainCreateScratchOrg
            - name: Open deploy page
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainOpenDeployPage
            - name: Execute Apex Before Deployment
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexBeforePush
            - name: Install Packages
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainInstallPackages
            - name: Deploy Metadata
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainDeploy
            - name: Execute Apex After Deployment
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexAfterPush
            - name: Assign Permission Set
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainAssignPermissionSet
            - name: Deply Admin Profile
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainDeplyAdminProfile
            - name: Load Data
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainLoadData
            - name: Execute Apex After Data
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexAfterData
            - name: Generate Password
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainGeneratePassword
            - name: Run Apex Tests
              run: ./@ELTOROIT/scripts/shell/CreateOrg.sh mainRunApexTests
```

# Bonus content

## ./@ELTOROIT/scripts/DeleteOrgs.sh

One of the things I like to do with scratch Orgs is to create more scratch orgs than needed. This process helps me know the metadata I have in the repo is complete, and that I will be able to create a scratch org at any time. It also helps me prove the demos I am sharing with the world can work. This creates a ton of scratch Orgs, that need to be cleaned!

This script looks for scratch orgs that do not have an alias associated (I may have re-used the alias with a new scratch org) and deletes them.

**Warning:** I am a Mac developer, and this script was created and tested on a Mac and Linux (<a href="https://github.com/features/actions">GitHub Actions</a> and <a href="https://developer.salesforce.com/blogs/2020/06/introducing-code-builder.html">Salesforce Code Builder</a>). I believe that it could be easily executed on Windows 10 using <a href="https://docs.microsoft.com/en-us/windows/wsl/">WSL</a>.
