import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import requests
import json
from datetime import datetime
import threading

class TeaYieldPredictorUI:
    def __init__(self, root):
        self.root = root
        self.root.title("iTeaGrow Yield Predictor")
        self.root.geometry("1200x800")
        
        # API Configuration
        self.api_url = "http://127.0.0.1:8000"
        
        # Create UI
        self.setup_ui()
        
        # Load feature order from API
        self.load_feature_order()
    
    def setup_ui(self):
        # Create notebook for tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Tab 1: Input Features
        self.input_frame = ttk.Frame(self.notebook)
        self.notebook.add(self.input_frame, text="Input Features")
        
        # Tab 2: Prediction Results
        self.result_frame = ttk.Frame(self.notebook)
        self.notebook.add(self.result_frame, text="Predictions")
        
        # Setup input tab
        self.setup_input_tab()
        
        # Setup result tab
        self.setup_result_tab()
    
    def setup_input_tab(self):
        # Create scrollable frame for features
        canvas = tk.Canvas(self.input_frame)
        scrollbar = ttk.Scrollbar(self.input_frame, orient="vertical", command=canvas.yview)
        self.scrollable_frame = ttk.Frame(canvas)
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # Labor input
        ttk.Label(self.scrollable_frame, text="LABOR INPUT", font=('Arial', 14, 'bold')).grid(row=0, column=0, columnspan=3, pady=(10, 5), sticky='w')
        
        ttk.Label(self.scrollable_frame, text="Labor Safe (workers):").grid(row=1, column=0, sticky='w', padx=5, pady=2)
        self.labor_var = tk.StringVar(value="70.0")
        ttk.Entry(self.scrollable_frame, textvariable=self.labor_var, width=15).grid(row=1, column=1, sticky='w', pady=2)
        
        ttk.Label(self.scrollable_frame, text="Division:").grid(row=2, column=0, sticky='w', padx=5, pady=2)
        self.division_var = tk.StringVar(value="ELT")
        division_combo = ttk.Combobox(self.scrollable_frame, textvariable=self.division_var, 
                                     values=["ELT", "LN", "LYN", "NC"], width=12)
        division_combo.grid(row=2, column=1, sticky='w', pady=2)
        
        ttk.Label(self.scrollable_frame, text="Prediction Date:").grid(row=3, column=0, sticky='w', padx=5, pady=2)
        self.date_var = tk.StringVar(value=datetime.now().strftime("%Y-%m-%d"))
        ttk.Entry(self.scrollable_frame, textvariable=self.date_var, width=15).grid(row=3, column=1, sticky='w', pady=2)
        
        # Separator
        ttk.Separator(self.scrollable_frame, orient='horizontal').grid(row=4, column=0, columnspan=3, sticky='ew', pady=10, padx=5)
        
        # Features input
        ttk.Label(self.scrollable_frame, text="FEATURE VALUES (44 total)", font=('Arial', 14, 'bold')).grid(row=5, column=0, columnspan=3, pady=(10, 5), sticky='w')
        
        # Will be populated after loading feature order
        self.feature_vars = []
        
        # Buttons
        button_frame = ttk.Frame(self.scrollable_frame)
        button_frame.grid(row=1000, column=0, columnspan=3, pady=20)
        
        ttk.Button(button_frame, text="📤 Load Example Values", command=self.load_example).pack(side='left', padx=5)
        ttk.Button(button_frame, text="🧹 Clear All", command=self.clear_all).pack(side='left', padx=5)
        ttk.Button(button_frame, text="🎯 Predict Yield", command=self.predict_yield, style='Accent.TButton').pack(side='left', padx=5)
        
        # Status label
        self.status_var = tk.StringVar(value="Ready")
        ttk.Label(self.scrollable_frame, textvariable=self.status_var, foreground='blue').grid(row=1001, column=0, columnspan=3, pady=5)
    
    def setup_result_tab(self):
        # Prediction result display
        result_container = ttk.Frame(self.result_frame)
        result_container.pack(fill='both', expand=True, padx=20, pady=20)
        
        # Result header
        header_frame = ttk.Frame(result_container)
        header_frame.pack(fill='x', pady=(0, 20))
        
        ttk.Label(header_frame, text="PREDICTION RESULTS", font=('Arial', 16, 'bold')).pack()
        ttk.Label(header_frame, text="Yield forecast for selected parameters", font=('Arial', 10)).pack()
        
        # Result cards
        card_frame = ttk.Frame(result_container)
        card_frame.pack(fill='x', pady=10)
        
        # Yield card
        yield_card = ttk.LabelFrame(card_frame, text="Predicted Yield", padding=20)
        yield_card.grid(row=0, column=0, padx=10, pady=10, sticky='nsew')
        
        self.yield_var = tk.StringVar(value="0.00 kg")
        ttk.Label(yield_card, textvariable=self.yield_var, font=('Arial', 24, 'bold')).pack()
        ttk.Label(yield_card, text="Total usable yield").pack()
        
        # Efficiency card
        eff_card = ttk.LabelFrame(card_frame, text="Log Efficiency", padding=20)
        eff_card.grid(row=0, column=1, padx=10, pady=10, sticky='nsew')
        
        self.eff_var = tk.StringVar(value="0.0000")
        ttk.Label(eff_card, textvariable=self.eff_var, font=('Arial', 20)).pack()
        ttk.Label(eff_card, text="Log efficiency score").pack()
        
        # Details card
        details_card = ttk.LabelFrame(result_container, text="Prediction Details", padding=15)
        details_card.pack(fill='both', expand=True, pady=10)
        
        self.details_text = scrolledtext.ScrolledText(details_card, height=10, font=('Consolas', 10))
        self.details_text.pack(fill='both', expand=True)
        
        # Button to copy result
        ttk.Button(result_container, text="📋 Copy Result", command=self.copy_result).pack(pady=10)
    
    def load_feature_order(self):
        """Load feature order from API"""
        try:
            response = requests.get(f"{self.api_url}/features")
            if response.status_code == 200:
                data = response.json()
                self.feature_order = data['feature_order']
                self.create_feature_inputs()
            else:
                messagebox.showerror("Error", "Failed to load feature order from API")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Cannot connect to API:\n{str(e)}")
    
    def create_feature_inputs(self):
        """Create input fields for all features"""
        row_start = 6
        
        # Group features by category
        categories = {
            "Division Features": ['Division_LN', 'Division_LYN', 'Division_NC'],
            "Humidity Features": ['Humidity_Mean_Pct', 'Humidity_Deficit', 'Humidity_3Day_Avg', 
                                 'Humidity_7Day_Avg', 'Humidity_Std_7Day', 'Consecutive_Stress_Days',
                                 'Humidity_Stress_Index', 'Humidity_Volatility', 'Is_Low_Humidity',
                                 'Is_High_Humidity', 'Extreme_Humidity_Stress'],
            "Temperature Features": ['Temperature_Daily_C', 'Temperature_7D_Avg', 
                                    'Temperature_14D_Avg', 'Temperature_28D_Avg'],
            "Rainfall Features": ['Rainfall_Daily_mm', 'Rainfall_7D_Avg', 'Rainfall_14D_Avg',
                                 'Rainfall_28D_Avg', 'Rain_7D_Sum', 'Rain_14D_Sum',
                                 'Rain_28D_Sum', 'Rain_4wk_Sum'],
            "VPD & Labor": ['VPD_kPa', 'Labor_Total', 'Labor_7D_Avg', 'Kg_Per_Worker_Potential'],
            "Crop & Yield": ['Crop_Harvested_Kg', 'Crop_7D_Avg', 'G_Pct', 'Total_Waste_Pct',
                            'Calculated_Waste_Pct', 'Yield_Momentum'],
            "Temporal Features": ['Month', 'Week_of_Year', 'Day_of_Year', 'Is_Weekend'],
            "Interaction Features": ['Crop_x_G_Pct', 'Labor_x_Temp', 'Humidity_x_Temp', 'Field_Intensity']
        }
        
        current_row = row_start
        self.feature_vars = []
        
        for category, features in categories.items():
            # Category header
            ttk.Label(self.scrollable_frame, text=category, font=('Arial', 12, 'bold')).grid(
                row=current_row, column=0, columnspan=3, pady=(15, 5), sticky='w'
            )
            current_row += 1
            
            # Create inputs for each feature in category
            for feature in features:
                if feature in self.feature_order:
                    idx = self.feature_order.index(feature)
                    
                    # Feature name
                    ttk.Label(self.scrollable_frame, text=feature, width=30, anchor='w').grid(
                        row=current_row, column=0, sticky='w', padx=5, pady=2
                    )
                    
                    # Input field
                    var = tk.StringVar(value="0.0")
                    self.feature_vars.append((feature, var))
                    
                    entry = ttk.Entry(self.scrollable_frame, textvariable=var, width=15)
                    entry.grid(row=current_row, column=1, sticky='w', pady=2)
                    
                    # Unit hint (based on feature name)
                    unit = self.get_unit_hint(feature)
                    if unit:
                        ttk.Label(self.scrollable_frame, text=unit, foreground='gray').grid(
                            row=current_row, column=2, sticky='w', padx=5
                        )
                    
                    current_row += 1
        
        # Update scroll region
        self.scrollable_frame.update_idletasks()
    
    def get_unit_hint(self, feature_name):
        """Get unit hint for feature"""
        if '_Pct' in feature_name or 'Is_' in feature_name:
            return "%"
        elif '_C' in feature_name:
            return "°C"
        elif '_mm' in feature_name:
            return "mm"
        elif '_kPa' in feature_name:
            return "kPa"
        elif '_Kg' in feature_name or 'kg' in feature_name.lower():
            return "kg"
        elif 'Labor' in feature_name:
            return "workers"
        elif 'Month' in feature_name or 'Week' in feature_name or 'Day' in feature_name:
            return ""
        elif 'Momentum' in feature_name or 'Intensity' in feature_name:
            return "ratio"
        else:
            return ""
    
    def load_example(self):
        """Load example values from API"""
        try:
            self.status_var.set("Loading example values...")
            
            response = requests.get(f"{self.api_url}/features/example")
            if response.status_code == 200:
                data = response.json()
                example_features = data['features']
                
                # Update labor safe
                self.labor_var.set(str(data['labor_safe']))
                
                # Update all feature values
                for i, (feature_name, var) in enumerate(self.feature_vars):
                    if i < len(example_features):
                        var.set(str(example_features[i]))
                
                self.status_var.set("Example values loaded!")
                messagebox.showinfo("Success", "Example values loaded successfully!")
            else:
                messagebox.showerror("Error", "Failed to load example values")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load example: {str(e)}")
        finally:
            self.status_var.set("Ready")
    
    def clear_all(self):
        """Clear all input fields"""
        for _, var in self.feature_vars:
            var.set("0.0")
        self.labor_var.set("70.0")
        self.division_var.set("ELT")
        self.status_var.set("All fields cleared")
    
    def predict_yield(self):
        """Make prediction using API"""
        # Validate inputs
        try:
            labor_safe = float(self.labor_var.get())
            if labor_safe <= 0:
                messagebox.showerror("Error", "Labor Safe must be greater than 0")
                return
        except ValueError:
            messagebox.showerror("Error", "Invalid Labor Safe value")
            return
        
        # Collect features
        features = []
        for feature_name, var in self.feature_vars:
            try:
                value = float(var.get())
                features.append(value)
            except ValueError:
                messagebox.showerror("Error", f"Invalid value for {feature_name}")
                return
        
        if len(features) != 44:
            messagebox.showerror("Error", f"Need exactly 44 features, got {len(features)}")
            return
        
        # Prepare request data
        request_data = {
            "features": features,
            "labor_safe": labor_safe,
            "division_id": self.division_var.get(),
            "prediction_date": self.date_var.get()
        }
        
        # Update status
        self.status_var.set("Making prediction...")
        
        # Make API call in thread to prevent UI freeze
        thread = threading.Thread(target=self.make_prediction_call, args=(request_data,))
        thread.daemon = True
        thread.start()
    
    def make_prediction_call(self, request_data):
        """Make actual API call (run in thread)"""
        try:
            response = requests.post(
                f"{self.api_url}/predict",
                json=request_data,
                headers={"Content-Type": "application/json"}
            )
            
            # Update UI in main thread
            self.root.after(0, self.handle_prediction_response, response)
            
        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", f"API Error: {str(e)}"))
            self.root.after(0, lambda: self.status_var.set("API Error"))
    
    def handle_prediction_response(self, response):
        """Handle API response"""
        if response.status_code == 200:
            result = response.json()
            
            # Update result display
            self.yield_var.set(f"{result['predicted_yield_kg']} kg")
            
            # Show in details
            details = f"✅ PREDICTION SUCCESSFUL\n"
            details += f"────────────────────────────\n"
            details += f"Division: {result['division_id']}\n"
            details += f"Predicted Yield: {result['predicted_yield_kg']} kg\n"
            details += f"Labor Safe: {request_data['labor_safe']} workers\n"
            details += f"Prediction Date: {request_data['prediction_date']}\n"
            details += f"Timestamp: {result['timestamp']}\n"
            details += f"────────────────────────────\n"
            details += f"Raw Response:\n{json.dumps(result, indent=2)}"
            
            self.details_text.delete(1.0, tk.END)
            self.details_text.insert(1.0, details)
            
            # Switch to results tab
            self.notebook.select(1)
            
            self.status_var.set("Prediction successful!")
            messagebox.showinfo("Success", f"Predicted Yield: {result['predicted_yield_kg']} kg")
            
        else:
            try:
                error = response.json()
                messagebox.showerror("API Error", f"Status {response.status_code}: {error.get('detail', 'Unknown error')}")
            except:
                messagebox.showerror("API Error", f"Status {response.status_code}: {response.text}")
            
            self.status_var.set("Prediction failed")
    
    def copy_result(self):
        """Copy prediction result to clipboard"""
        result_text = f"Predicted Yield: {self.yield_var.get()}\n"
        result_text += f"Log Efficiency: {self.eff_var.get()}\n"
        result_text += self.details_text.get(1.0, tk.END)
        
        self.root.clipboard_clear()
        self.root.clipboard_append(result_text)
        messagebox.showinfo("Copied", "Prediction results copied to clipboard!")

def main():
    root = tk.Tk()
    
    # Set style
    style = ttk.Style()
    style.theme_use('clam')
    
    # Create accent button style
    style.configure('Accent.TButton', font=('Arial', 10, 'bold'), foreground='white')
    style.map('Accent.TButton',
              background=[('active', '#0052cc'), ('!disabled', '#0066ff')],
              foreground=[('!disabled', 'white')])
    
    app = TeaYieldPredictorUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()