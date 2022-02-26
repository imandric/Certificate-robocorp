*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser
Library           RPA.HTTP
Library           Process
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           Screenshot
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${Search_query}=    Collect Order link from user
    Open the robot order website
    Download the order file    ${Search_query}
    ${Orders}=    Get order
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create ZIP package from PDF files

*** Keywords ***
Collect Order link from user
    Add text input    search    Input Excel link
    ${User_input}=    Run dialog
    [Return]    ${User_input.search}

Open the robot order website
    ${secret}=    Get Secret    Site Url
    Open Available Browser    ${secret}[url]
    Maximize Browser Window

Download the order file
    [Arguments]    ${Search_query}
    Download    ${Search_query}    overwrite=true
    ...    target_file=${CURDIR}${/}devdata

Get order
    ${tables}=    Read table from CSV    ${CURDIR}${/}devdata${/}orders.csv
    ...    header= True
    [Return]    ${tables}

Close the annoying modal
    Wait Until Element Is Visible    xpath: //div[@class='modal-content']
    Click Button    xpath: //button[@class='btn btn-dark']

Fill the form
    [Arguments]    ${row}
    Click Element    xpath: //select[@id='head']
    Click Element    xpath: //select[@id='head']/option[@value='${row}[Head]']
    Click Element    xpath: //div[@class='radio form-check']/label[@for='id-body-${row}[Body]']
    Input Text    Xpath: //input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    xpath: //input[@id='address']    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_folder_path}    Set Variable    ${OUTPUT_DIR}${/}receipt${/}${row}[Order number].Pdf
    Html To Pdf    ${receipt_html}    ${pdf_folder_path}
    [Return]    ${pdf_folder_path}

Take a screenshot of the robot
    [Arguments]    ${row}
    ${screenshot_path}    Set Variable    ${OUTPUT_DIR}${/}screenshot${/}${row}[Order number].PNG
    Screenshot    id:robot-preview-image    ${screenshot_path}
    [Return]    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${receipt_pdf}=    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${receipt_pdf}

Go to order another robot
    Wait Until Keyword Succeeds    10x    2s    Click Button    xpath: //button[@id='order-another']

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${CURDIR}${/}temp${/}PDFs.zip
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipt    ${zip_file_name}
