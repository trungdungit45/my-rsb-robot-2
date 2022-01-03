*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.Robocorp.Vault
Library    RPA.HTTP   
Library    RPA.Excel.Files
Library    RPA.PDF
Library    RPA.Tables
Library    Dialogs
Library    RPA.FileSystem
Library    RPA.Archive
Variables   variables.py

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # Get and log the value of the vault secrets using the Get Secret keyword
    ${settings}=    Get Secret    settings
    Log    ${settings}[rsb_oder_data_url]     # Oder data url
    Log    ${settings}[rsb_web_url]    # RSB website oder url

    # Start process
    ${orders}=    Get orders    ${settings}[rsb_oder_data_url]
    Log    Starting oder robot!
    Open the robot order website    ${settings}[rsb_web_url]
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Submit the order
        ${error}=    Is Element Visible    css:div.alert-danger
        IF    ${error} == ${True}
            ${error_message}=    Get Text    css:div.alert-danger
            Log    Oder ${row}[Order number]: Submit failed with error: ${error_message}
            
        ELSE
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Log    Oder ${row}[Order number]: Submit successfully
            Go to order another robot 
        END
    END
    Create a ZIP file of the receipts
    Close Browser
    
*** Keywords ***
Open the robot order website
    [Arguments]    ${rsb_web_url}
    Open Available Browser    ${rsb_web_url}    maximized=${True}    
Get orders
    [Arguments]    ${rsb_oder_data_url}
    Download    ${rsb_oder_data_url}    overwrite=${True}
    ${csv_data}  Read table from CSV    orders.csv    header=${True}
    [Return]    ${csv_data}
Close the annoying modal
    Wait Until Element Is Visible    id:preview
    ${btn_OK_visible}=    Is Element Visible    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]
    IF    ${btn_OK_visible} == ${True}
        Click Element When Visible    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]   
    ELSE
        Log    button OK not visible  
    END
       

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://*/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
Preview the robot
    Wait Until Element Is Visible    id:preview
    Click Button    id:preview
Submit the order
    Wait Until Element Is Visible    id:preview
    Click Button    id:order
Store the receipt as a PDF file
    [Arguments]    ${oder_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_${oder_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    [Return]    ${pdf}
Take a screenshot of the robot
    [Arguments]    ${oder_number}
    ${screenshot}    Set Variable    ${OUTPUT_DIR}${/}receipts${/}robot_${oder_number}.png
    Screenshot    id:robot-preview-image    ${screenshot}
    [Return]    ${screenshot}
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${receipt_PDF}=    Open Pdf    ${pdf}
    ${robot_png}=    Create List     ${pdf}    ${screenshot}    
    Add Files To Pdf    ${robot_png}    ${pdf}  
    Close Pdf    ${receipt_PDF}
Go to order another robot
    Click Element When Visible    id:order-another
Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip