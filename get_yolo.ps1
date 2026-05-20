Write-Host "Creating Python virtual environment..."
python -m venv yolovenv
Write-Host "Installing ultralytics in venv..."
.\yolovenv\Scripts\python.exe -m pip install ultralytics
Write-Host "Exporting YOLOv8n to TFLite..."
.\yolovenv\Scripts\yolo.exe export model=yolov8n.pt format=tflite
Write-Host "Moving the generated model to assets/models..."
If (Test-Path "yolov8n_saved_model\yolov8n_float32.tflite") {
    Move-Item -Path "yolov8n_saved_model\yolov8n_float32.tflite" -Destination "c:\flutter_projects\pelita\assets\models\" -Force
    Write-Host "Model moved successfully!"
} Else {
    Write-Host "Error: Model file not found!"
}
Write-Host "Cleaning up..."
If (Test-Path "yolov8n_saved_model") { Remove-Item -Recurse -Force "yolov8n_saved_model" }
If (Test-Path "yolov8n.pt") { Remove-Item "yolov8n.pt" }
Write-Host "Process completed."
