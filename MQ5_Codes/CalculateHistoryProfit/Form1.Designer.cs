using System;
using System.Drawing;
using System.Windows.Forms;

namespace MtGuiControllerForm
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.Picker_DateStart = new System.Windows.Forms.DateTimePicker();
            this.Picker_DateEnd = new System.Windows.Forms.DateTimePicker();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.groupBox = new System.Windows.Forms.GroupBox();
            this.b_year = new System.Windows.Forms.Button();
            this.b_month = new System.Windows.Forms.Button();
            this.b_week = new System.Windows.Forms.Button();
            this.b_today = new System.Windows.Forms.Button();
            this.label_hidden_live = new System.Windows.Forms.Label();
            this.check_shutdown = new System.Windows.Forms.CheckBox();
            this.button_submit = new System.Windows.Forms.Button();
            this.btn_live = new System.Windows.Forms.Button();
            this.label_hidden_calc = new System.Windows.Forms.Label();
            this.check_pip = new System.Windows.Forms.CheckBox();
            this.groupBox.SuspendLayout();
            this.SuspendLayout();
            // 
            // Picker_DateStart
            // 
            this.Picker_DateStart.AccessibleDescription = "";
            this.Picker_DateStart.AccessibleName = "";
            this.Picker_DateStart.AllowDrop = true;
            this.Picker_DateStart.Cursor = System.Windows.Forms.Cursors.Hand;
            this.Picker_DateStart.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
            this.Picker_DateStart.Location = new System.Drawing.Point(141, 25);
            this.Picker_DateStart.MaxDate = new System.DateTime(2030, 12, 31, 0, 0, 0, 0);
            this.Picker_DateStart.MinDate = new System.DateTime(1970, 1, 1, 0, 0, 0, 0);
            this.Picker_DateStart.Name = "Picker_DateStart";
            this.Picker_DateStart.Size = new System.Drawing.Size(173, 23);
            this.Picker_DateStart.TabIndex = 1;
            this.Picker_DateStart.Value = new System.DateTime(2024, 1, 1, 0, 0, 0, 0);
            this.Picker_DateStart.ValueChanged += new System.EventHandler(this.Piсker_DateStart_ValueChanged);
            // 
            // Picker_DateEnd
            // 
            this.Picker_DateEnd.AllowDrop = true;
            this.Picker_DateEnd.Cursor = System.Windows.Forms.Cursors.Hand;
            this.Picker_DateEnd.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
            this.Picker_DateEnd.Location = new System.Drawing.Point(141, 65);
            this.Picker_DateEnd.MaxDate = new System.DateTime(2030, 12, 31, 0, 0, 0, 0);
            this.Picker_DateEnd.MinDate = new System.DateTime(1970, 1, 1, 0, 0, 0, 0);
            this.Picker_DateEnd.Name = "Picker_DateEnd";
            this.Picker_DateEnd.Size = new System.Drawing.Size(173, 23);
            this.Picker_DateEnd.TabIndex = 2;
            this.Picker_DateEnd.Value = new System.DateTime(2024, 12, 31, 23, 59, 0, 0);
            this.Picker_DateEnd.ValueChanged += new System.EventHandler(this.Piсker_DateEnd_ValueChanged);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F);
            this.label1.Location = new System.Drawing.Point(57, 30);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(72, 17);
            this.label1.TabIndex = 3;
            this.label1.Text = "Start Date";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F);
            this.label2.Location = new System.Drawing.Point(62, 70);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(67, 17);
            this.label2.TabIndex = 4;
            this.label2.Text = "End Date";
            // 
            // groupBox
            // 
            this.groupBox.Controls.Add(this.b_year);
            this.groupBox.Controls.Add(this.b_month);
            this.groupBox.Controls.Add(this.b_week);
            this.groupBox.Controls.Add(this.b_today);
            this.groupBox.Controls.Add(this.label2);
            this.groupBox.Controls.Add(this.label1);
            this.groupBox.Controls.Add(this.Picker_DateEnd);
            this.groupBox.Controls.Add(this.Picker_DateStart);
            this.groupBox.Location = new System.Drawing.Point(41, 6);
            this.groupBox.Name = "groupBox";
            this.groupBox.Size = new System.Drawing.Size(390, 160);
            this.groupBox.TabIndex = 10;
            this.groupBox.TabStop = false;
            this.groupBox.Text = "Settings";
            // 
            // b_year
            // 
            this.b_year.BackColor = System.Drawing.Color.Thistle;
            this.b_year.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.25F);
            this.b_year.Location = new System.Drawing.Point(285, 108);
            this.b_year.Name = "b_year";
            this.b_year.Size = new System.Drawing.Size(68, 28);
            this.b_year.TabIndex = 14;
            this.b_year.Text = "Year";
            this.b_year.UseVisualStyleBackColor = false;
            // 
            // b_month
            // 
            this.b_month.BackColor = System.Drawing.Color.Aquamarine;
            this.b_month.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.25F);
            this.b_month.Location = new System.Drawing.Point(200, 108);
            this.b_month.Name = "b_month";
            this.b_month.Size = new System.Drawing.Size(68, 28);
            this.b_month.TabIndex = 13;
            this.b_month.Text = "Month";
            this.b_month.UseVisualStyleBackColor = false;
            // 
            // b_week
            // 
            this.b_week.BackColor = System.Drawing.Color.LightGreen;
            this.b_week.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.25F);
            this.b_week.Location = new System.Drawing.Point(115, 108);
            this.b_week.Name = "b_week";
            this.b_week.Size = new System.Drawing.Size(68, 28);
            this.b_week.TabIndex = 12;
            this.b_week.Text = "Week";
            this.b_week.UseVisualStyleBackColor = false;
            // 
            // b_today
            // 
            this.b_today.BackColor = System.Drawing.Color.Khaki;
            this.b_today.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.25F);
            this.b_today.Location = new System.Drawing.Point(30, 108);
            this.b_today.Name = "b_today";
            this.b_today.Size = new System.Drawing.Size(68, 28);
            this.b_today.TabIndex = 11;
            this.b_today.Text = "Today";
            this.b_today.UseVisualStyleBackColor = false;
            // 
            // label_hidden_live
            // 
            this.label_hidden_live.AutoSize = true;
            this.label_hidden_live.Font = new System.Drawing.Font("Microsoft Sans Serif", 0.05F);
            this.label_hidden_live.Location = new System.Drawing.Point(40, 179);
            this.label_hidden_live.Name = "label_hidden_live";
            this.label_hidden_live.Size = new System.Drawing.Size(12, 2);
            this.label_hidden_live.TabIndex = 15;
            this.label_hidden_live.Text = "hidden_text";
            this.label_hidden_live.Visible = false;
            this.label_hidden_live.TextChanged += new System.EventHandler(this.HiddenTable_TextChanged);
            // 
            // check_shutdown
            // 
            this.check_shutdown.AutoSize = true;
            this.check_shutdown.Location = new System.Drawing.Point(10, 186);
            this.check_shutdown.Name = "check_shutdown";
            this.check_shutdown.Size = new System.Drawing.Size(15, 14);
            this.check_shutdown.TabIndex = 9;
            this.check_shutdown.UseVisualStyleBackColor = false;
            this.check_shutdown.Visible = false;
            this.check_shutdown.CheckedChanged += new System.EventHandler(this.checkBox1_CheckedChanged);
            // 
            // button_submit
            // 
            this.button_submit.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F);
            this.button_submit.Location = new System.Drawing.Point(328, 172);
            this.button_submit.Name = "button_submit";
            this.button_submit.Size = new System.Drawing.Size(104, 29);
            this.button_submit.TabIndex = 0;
            this.button_submit.Text = "Calculate";
            this.button_submit.UseVisualStyleBackColor = true;
            this.button_submit.Click += new System.EventHandler(this.btn_calc_Click);
            // 
            // btn_live
            // 
            this.btn_live.Font = new System.Drawing.Font("Microsoft Sans Serif", 7.25F);
            this.btn_live.Location = new System.Drawing.Point(10, 11);
            this.btn_live.Margin = new System.Windows.Forms.Padding(0);
            this.btn_live.Name = "btn_live";
            this.btn_live.Size = new System.Drawing.Size(23, 155);
            this.btn_live.TabIndex = 16;
            this.btn_live.Text = "<<\r\n\r\n\r\nL\r\nI\r\nV\r\nE\r\n\r\n\r\n<<";
            this.btn_live.UseVisualStyleBackColor = true;
            this.btn_live.Click += new System.EventHandler(this.btn_live_Click);
            // 
            // label_hidden_calc
            // 
            this.label_hidden_calc.AutoSize = true;
            this.label_hidden_calc.Font = new System.Drawing.Font("Microsoft Sans Serif", 0.05F);
            this.label_hidden_calc.Location = new System.Drawing.Point(40, 198);
            this.label_hidden_calc.Name = "label_hidden_calc";
            this.label_hidden_calc.Size = new System.Drawing.Size(12, 2);
            this.label_hidden_calc.TabIndex = 18;
            this.label_hidden_calc.Text = "hidden_text";
            this.label_hidden_calc.Visible = false;
            this.label_hidden_calc.TextChanged += new System.EventHandler(this.HiddenTable_TextChanged_calc);
            // 
            // check_pip
            // 
            this.check_pip.AutoSize = true;
            this.check_pip.CheckAlign = System.Drawing.ContentAlignment.MiddleRight;
            this.check_pip.Location = new System.Drawing.Point(238, 178);
            this.check_pip.Name = "check_pip";
            this.check_pip.Size = new System.Drawing.Size(79, 17);
            this.check_pip.TabIndex = 19;
            this.check_pip.Text = "calc in pips";
            this.check_pip.UseVisualStyleBackColor = true;
            this.check_pip.Visible = false;
            this.check_pip.CheckedChanged += new System.EventHandler(this.checkBoxPIP_CheckedChanged);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(440, 208);
            this.Controls.Add(this.check_pip);
            this.Controls.Add(this.label_hidden_calc);
            this.Controls.Add(this.btn_live);
            this.Controls.Add(this.label_hidden_live);
            this.Controls.Add(this.check_shutdown);
            this.Controls.Add(this.button_submit);
            this.Controls.Add(this.groupBox);
            this.Location = new System.Drawing.Point(450, 140);
            this.Name = "Form1";
            this.StartPosition = System.Windows.Forms.FormStartPosition.Manual;
            this.Text = "Profit Calculator";
            this.LocationChanged += new System.EventHandler(this.Form1_LocationChanged);
            this.groupBox.ResumeLayout(false);
            this.groupBox.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.DateTimePicker Picker_DateEnd;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.GroupBox groupBox;
        private System.Windows.Forms.CheckBox check_shutdown;
        public System.Windows.Forms.DateTimePicker Picker_DateStart;
        private System.Windows.Forms.Button b_year;
        private System.Windows.Forms.Button b_month;
        private System.Windows.Forms.Button b_week;
        private System.Windows.Forms.Button b_today;
        private System.Windows.Forms.Label label_hidden_live;
        private Button button_submit;
        private Button btn_live;
        private Label label_hidden_calc;
        private CheckBox check_pip;
    }


}