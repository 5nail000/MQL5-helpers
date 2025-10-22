using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MtGuiControllerForm
{
    public partial class Form1 : Form
    {

        Form newForm = new Form();
        private DataGridView dataGridView;
        private DataTable dataTable; // Ссылка на DataTable
        private bool isFormVisible = false;
        private const int MaxRowsVisible = 100; // Максимальное количество видимых строк
        private const int RowHeight = 22; // Высота строки в пикселях (обычно 22 для стандартного шрифта)

        Form newForm_calc = new Form();
        private DataGridView dataGridView_calc;
        private DataTable dataTable_calc; // Ссылка на DataTable

        public Form1()
        {
            InitializeComponent();
            InitializeDataTable();
            InitializeNewForm();
            InitializeDataTable_calc();
            InitializeNewForm_calc();
        }
        private void InitializeDataTable()
        {
            // Создание DataTable и добавление столбцов
            dataTable = new DataTable();
            dataTable.Columns.Add("Magic");
            dataTable.Columns.Add("Symbol");
            dataTable.Columns.Add("Profit");
        }
        private void InitializeDataTable_calc()
        {
            // Создание DataTable и добавление столбцов
            dataTable_calc = new DataTable();
            dataTable_calc.Columns.Add("Magic");
            dataTable_calc.Columns.Add("Symbol");
            dataTable_calc.Columns.Add("Profit");
            dataTable_calc.Columns.Add("maxDD");
            dataTable_calc.Columns.Add("Deals");
        }

        private void InitializeNewForm()
        {
            newForm.FormBorderStyle = FormBorderStyle.None;
            newForm.StartPosition = FormStartPosition.Manual;
            newForm.Size = new Size(300, 400);
            newForm.TopMost = true; // Делаем форму сверху
            newForm.ShowInTaskbar = false; // Не показываем в панели задач
            newForm.Enabled = false; // Блокируем взаимодействие с формой
            newForm.Click += new EventHandler(DataTable_Click);

            DataGridView dataGridView = new DataGridView();
            dataGridView.Name = "dataGridView";
            dataGridView.Size = new Size(300, 22);
            dataGridView.Location = new Point(0, 0);
            
            dataGridView.AllowUserToAddRows = false;
            dataGridView.AllowUserToDeleteRows = false;
            dataGridView.Dock = DockStyle.Top;
            dataGridView.RowHeadersVisible = false;
            dataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridView.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;

            // Установка DataSource для DataGridView
            dataGridView.DataSource = dataTable;
            dataGridView.ClearSelection();
            dataGridView.CurrentCell = null;
            // Подписка на событие CellFormatting
            newForm.Controls.Add(dataGridView);
        }
        private void InitializeNewForm_calc()
        {
            newForm_calc.FormBorderStyle = FormBorderStyle.None;
            newForm_calc.StartPosition = FormStartPosition.Manual;
            newForm_calc.Size = new Size(500, 22);
            newForm_calc.TopMost = true; // Делаем форму сверху
            newForm_calc.ShowInTaskbar = false; // Не показываем в панели задач
            newForm_calc.Enabled = false; // Блокируем взаимодействие с формой
            newForm_calc.Click += new EventHandler(DataTable_Click);

            DataGridView dataGridView_calc = new DataGridView();
            dataGridView_calc.Name = "dataGridView_calc";
            dataGridView_calc.Size = new Size(500, 22);
            dataGridView_calc.Location = new Point(0, 0);

            dataGridView_calc.AllowUserToAddRows = false;
            dataGridView_calc.AllowUserToDeleteRows = false;
            dataGridView_calc.RowHeadersVisible = false;
            dataGridView_calc.Dock = DockStyle.Top;
            dataGridView_calc.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridView_calc.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
            dataGridView_calc.ScrollBars = ScrollBars.Vertical;

            // Установка DataSource для DataGridView
            dataGridView_calc.DataSource = dataTable_calc;
            dataGridView_calc.ClearSelection();
            dataGridView_calc.CurrentCell = null;
            // Подписка на событие CellFormatting
            newForm_calc.Controls.Add(dataGridView_calc);
        }
        private void DataTable_Click(object sender, EventArgs e)
        {
            // Устанавливаем Form1 как верхнюю и активируем её
            // this.TopMost = true;  // Делает Form1 верхней над другими окнами
            this.BringToFront();  // Переносит Form1 на передний план
            // this.Focus();  // Фокусируем Form1
        }
        public void UpdateData(string sparam)
        {
            if (dataTable == null)
            {
                MessageBox.Show("DataTable is not initialized.");
                return;
            }

            dataTable.Clear();

            // Обновление данных в DataTable
            var rows = sparam.Split(';');
            foreach (var row in rows)
            {
                // MessageBox.Show(row); // Отладочное сообщение
                var columns = row.Split(',');
                if (columns.Length == dataTable.Columns.Count) // Убедитесь, что количество столбцов совпадает
                {
                    dataTable.Rows.Add(columns);
                }
            }

            // Обновление DataGridView
            DataGridView dataGridView = newForm.Controls.Find("dataGridView", true).FirstOrDefault() as DataGridView;
            if (dataGridView != null)
            {
                AdjustFormHeight(dataGridView);
                foreach (DataGridViewColumn column in dataGridView.Columns)
                {
                    column.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                }
                dataGridView.Refresh(); // Обновляем отображение таблицы
                dataGridView.ClearSelection();
                dataGridView.CurrentCell = null;
            }
            else
            {
                MessageBox.Show("DataGridView not found.");
            }
        }
        public void UpdateData_calc(string sparam)
        {
            if (dataTable_calc == null)
            {
                MessageBox.Show("DataTable_calc is not initialized.");
                return;
            }

            dataTable_calc.Clear();

            // Обновление данных в DataTable
            var rows = sparam.Split(';');
            foreach (var row in rows)
            {
                // MessageBox.Show(row); // Отладочное сообщение
                var columns = row.Split(',');
                if (columns.Length == dataTable_calc.Columns.Count) // Убедитесь, что количество столбцов совпадает
                {
                    dataTable_calc.Rows.Add(columns);
                }
            }

            // Обновление DataGridView
            DataGridView dataGridView_calc = newForm_calc.Controls.Find("dataGridView_calc", true).FirstOrDefault() as DataGridView;
            if (dataGridView_calc != null)
            {
                AdjustFormHeight_calc(dataGridView_calc);
                foreach (DataGridViewColumn column in dataGridView_calc.Columns)
                {
                    column.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                }
                dataGridView_calc.Refresh(); // Обновляем отображение таблицы
                dataGridView_calc.ClearSelection();
                dataGridView_calc.CurrentCell = null;
            }
            else
            {
                MessageBox.Show("DataGridView_calc not found.");
            }
        }
        private void AdjustFormHeight(DataGridView dataGridView)
        {
            // Получаем количество строк в DataGridView
            int rowCount = dataTable.Rows.Count +2;

            // Ограничиваем видимые строки до MaxRowsVisible
            // int visibleRowCount = rowCount > MaxRowsVisible ? MaxRowsVisible : rowCount;
            int visibleRowCount = Math.Min(rowCount, MaxRowsVisible);

            // Устанавливаем высоту DataGridView в зависимости от количества строк
            dataGridView.Size = new Size(300, visibleRowCount * RowHeight);

            // Вычисляем высоту формы с учетом DataGridView
            newForm.Height = dataGridView.Height - RowHeight;
        }

        private void AdjustFormHeight_calc(DataGridView dataGridView_calc)
        {
            // Получаем количество строк в DataGridView
            int rowCount = dataTable_calc.Rows.Count + 2;

            // Ограничиваем видимые строки до MaxRowsVisible
            // int visibleRowCount = rowCount > MaxRowsVisible ? MaxRowsVisible : rowCount;
            int visibleRowCount = Math.Min(rowCount, MaxRowsVisible);

            // Устанавливаем высоту DataGridView в зависимости от количества строк
            dataGridView_calc.Size = new Size(500, visibleRowCount * RowHeight);

            // Вычисляем высоту формы с учетом DataGridView
            newForm_calc.Height = dataGridView_calc.Height - RowHeight;
        }

        private void HiddenTable_TextChanged(object sender, EventArgs e)
        {
            // Получаем данные из скрытого текстового поля
            string data = label_hidden_live.Text;
            UpdateData(data); // Вызываем метод обновления данных
        }

        private void HiddenTable_TextChanged_calc(object sender, EventArgs e)
        {
            // Получаем данные из скрытого текстового поля
            string data = label_hidden_calc.Text;
            UpdateData_calc(data); // Вызываем метод обновления данных
        }

        private void btn_live_Click(object sender, EventArgs e)
        {
            if (isFormVisible)
            {
                newForm.Hide();
            }
            else
            {
                // Позиция новой формы слева от основной
                int newFormX = this.Left - newForm.Width;
                int newFormY = this.Top + SystemInformation.CaptionHeight; // Под полосой заголовка

                // Получаем ширину экрана
                int screenWidth = Screen.PrimaryScreen.WorkingArea.Width;

                // Проверяем, выходит ли новая форма за пределы экрана слева
                if (newFormX < 0)
                {
                    // Сдвигаем основную форму вправо, если новая форма не помещается слева
                    int offset = Math.Abs(newFormX); // Величина сдвига
                    if (this.Left + offset + this.Width <= screenWidth)
                    {
                        this.Left += offset; // Сдвигаем основную форму вправо
                        newFormX = 0; // Выравниваем новую форму по левому краю экрана
                    }
                    else
                    {
                        // Если не хватает места для сдвига основной формы, просто размещаем новую форму по левому краю
                        newFormX = 0;
                    }
                }

                // Устанавливаем позицию новой формы
                newForm.Location = new Point(newFormX, newFormY);
                newForm.Show();
                // Сброс выделения в DataGridView
                DataGridView dataGridView = newForm.Controls.Find("dataGridView", true).FirstOrDefault() as DataGridView;
                if (dataGridView != null)
                {
                    dataGridView.ClearSelection();
                    dataGridView.CurrentCell = null;
                }
            }
            isFormVisible = !isFormVisible;
        }

        private void btn_calc_Click(object sender, EventArgs e)
        {
            // Позиция новой формы справа от основной
            int newFormCalcX = this.Right; // Справа от основной формы
            int newFormCalcY = this.Top + SystemInformation.CaptionHeight; // Под полосой заголовка

            // Получаем ширину экрана
            int screenWidth = Screen.PrimaryScreen.WorkingArea.Width;

            // Проверяем, выходит ли новая форма за пределы экрана справа
            if (newFormCalcX + newForm_calc.Width > screenWidth)
            {
                // Если форма выходит за экран, выравниваем по правому краю экрана
                newFormCalcX = screenWidth - newForm_calc.Width;
            }

            // Устанавливаем позицию новой формы
            newForm_calc.Location = new Point(newFormCalcX, newFormCalcY);
            newForm_calc.Show();

            // Сброс выделения в DataGridView
            DataGridView dataGridView_calc = newForm_calc.Controls.Find("dataGridView_calc", true).FirstOrDefault() as DataGridView;
            if (dataGridView_calc != null)
            {
                dataGridView_calc.ClearSelection();
                dataGridView_calc.CurrentCell = null;
            }
        }

        private void Form1_LocationChanged(object sender, EventArgs e)
        {
            // Обновляем позицию дополнительной формы (слева) при перемещении главной
            int newFormX = this.Left - newForm.Width;
            int newFormY = this.Top + SystemInformation.CaptionHeight; // Под полосой заголовка

            // Проверяем, чтобы новая форма не выходила за пределы экрана
            if (newFormX < 0)
            {
                newFormX = 0; // Если форма заходит за пределы экрана слева, то выравниваем по левому краю экрана
            }

            newForm.Location = new Point(newFormX, newFormY);

            // Обновляем позицию дополнительной формы (справа) при перемещении главной
            int newFormCalcX = this.Right; // Справа от основной формы
            int newFormCalcY = this.Top + SystemInformation.CaptionHeight; // Под полосой заголовка

            // Получаем ширину экрана
            int screenWidth = Screen.PrimaryScreen.WorkingArea.Width;

            // Проверяем, выходит ли новая форма за пределы экрана справа
            if (newFormCalcX + newForm_calc.Width > screenWidth)
            {
                newFormCalcX = screenWidth - newForm_calc.Width; // Выравниваем по правому краю экрана
            }

            newForm_calc.Location = new Point(newFormCalcX, newFormCalcY);
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {

        }
        private void checkBoxPIP_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void Piсker_DateStart_ValueChanged(object sender, EventArgs e)
        {
            DateTime selectedDate = Picker_DateStart.Value;
        }

        private void Piсker_DateEnd_ValueChanged(object sender, EventArgs e)
        {
            DateTime selectedDate = Picker_DateEnd.Value;
        }
    }
}
