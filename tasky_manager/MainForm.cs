using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Newtonsoft.Json;

namespace TaskyManager
{
    public partial class MainForm : Form
    {
        private NumericUpDown numClients = null!;
        private Button btnStart = null!;
        private Button btnStop = null!;
        private Button btnStartBackend = null!;
        private Button btnStopBackend = null!;
        private DataGridView gridClients = null!;
        private TextBox txtBackendLog = null!;
        private Label lblStatus = null!;
        
        private List<ClientInstance> clients = new List<ClientInstance>();
        private Process backendProcess;
        private readonly HttpClient httpClient = new HttpClient();
        private readonly string baseUrl = "http://localhost:4000/api";
        private readonly string projectPath;
        private readonly string flutterPath;

        public MainForm()
        {
            // Đọc config file nếu có
            var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config.txt");
            
            if (File.Exists(configPath))
            {
                try
                {
                    var lines = File.ReadAllLines(configPath);
                    foreach (var line in lines)
                    {
                        if (line.StartsWith("PROJECT_PATH="))
                        {
                            projectPath = line.Substring("PROJECT_PATH=".Length).Trim();
                        }
                    }
                }
                catch { }
            }
            
            // Fallback: tìm đường dẫn project tự động
            if (string.IsNullOrEmpty(projectPath))
            {
                var currentDir = AppDomain.CurrentDomain.BaseDirectory;
                
                // Nếu đang chạy từ bin/Release/... thì lùi về
                if (currentDir.Contains(@"\bin\"))
                {
                    var binIndex = currentDir.IndexOf(@"\bin\");
                    projectPath = currentDir.Substring(0, binIndex);
                    // Lùi thêm 1 cấp để ra khỏi tasky_manager
                    projectPath = Path.GetFullPath(Path.Combine(projectPath, ".."));
                }
                else
                {
                    // Fallback cuối: hardcoded path
                    projectPath = @"d:\project\Lập Trình Di Động\Tasky";
                }
            }
            
            // Tìm Flutter
            flutterPath = FindFlutter();
            
            InitializeComponent();
            SetupDataGrid();
            
            this.Text = "🌸 Tasky Manager - Multi-Client Testing Tool";
            this.Size = new Size(1200, 800);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(255, 250, 245); // Pastel cream
            
            LogBackend($"Project path: {projectPath}");
        }

        private void InitializeComponent()
        {
            // Header Panel
            var headerPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 120,
                BackColor = Color.FromArgb(255, 230, 210),
                Padding = new Padding(20)
            };

            var titleLabel = new Label
            {
                Text = "🌸 TASKY MANAGER",
                Font = new Font("Segoe UI", 24, FontStyle.Bold),
                ForeColor = Color.FromArgb(100, 80, 120),
                AutoSize = true,
                Location = new Point(20, 15)
            };

            var subtitleLabel = new Label
            {
                Text = "Multi-Client Testing & Interaction Simulator",
                Font = new Font("Segoe UI", 12),
                ForeColor = Color.FromArgb(120, 100, 140),
                AutoSize = true,
                Location = new Point(20, 55)
            };

            lblStatus = new Label
            {
                Text = "⚪ Backend: Not Running",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.FromArgb(200, 100, 100),
                AutoSize = true,
                Location = new Point(20, 85)
            };

            headerPanel.Controls.AddRange(new Control[] { titleLabel, subtitleLabel, lblStatus });

            // Control Panel
            var controlPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 100,
                BackColor = Color.FromArgb(245, 240, 235),
                Padding = new Padding(20)
            };

            var label1 = new Label
            {
                Text = "Số lượng Client:",
                Location = new Point(20, 15),
                AutoSize = true,
                Font = new Font("Segoe UI", 10)
            };

            numClients = new NumericUpDown
            {
                Minimum = 1,
                Maximum = 5,
                Value = 2,
                Location = new Point(150, 12),
                Width = 80,
                Font = new Font("Segoe UI", 10)
            };

            var noteLabel = new Label
            {
                Text = "💡 Mỗi client sẽ mở trong Edge browser riêng biệt. Bạn tự đăng ký/đăng nhập.",
                Location = new Point(20, 45),
                AutoSize = true,
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.FromArgb(100, 100, 100)
            };

            btnStartBackend = CreateButton("🚀 Start Backend", new Point(300, 10), Color.FromArgb(180, 220, 180));
            btnStartBackend.Click += BtnStartBackend_Click;

            btnStopBackend = CreateButton("🛑 Stop Backend", new Point(450, 10), Color.FromArgb(255, 180, 180));
            btnStopBackend.Click += BtnStopBackend_Click;
            btnStopBackend.Enabled = false;

            btnStart = CreateButton("▶️ Start Clients", new Point(300, 50), Color.FromArgb(200, 230, 255));
            btnStart.Click += BtnStart_Click;
            btnStart.Width = 250;

            btnStop = CreateButton("⏹️ Stop All Clients", new Point(300, 50), Color.FromArgb(255, 200, 200));
            btnStop.Click += BtnStop_Click;
            btnStop.Enabled = false;
            btnStop.Width = 250;
            btnStop.Visible = false; // Ẩn ban đầu

            controlPanel.Controls.AddRange(new Control[] { 
                label1, numClients, noteLabel,
                btnStartBackend, btnStopBackend, btnStart, btnStop 
            });

            // Grid Panel
            var gridPanel = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(20)
            };

            gridClients = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                BackgroundColor = Color.White,
                BorderStyle = BorderStyle.None,
                RowHeadersVisible = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                Font = new Font("Segoe UI", 9)
            };

            gridPanel.Controls.Add(gridClients);

            // Backend Log Panel
            var logPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 150,
                Padding = new Padding(20, 10, 20, 20)
            };

            var logLabel = new Label
            {
                Text = "Backend Log:",
                Dock = DockStyle.Top,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                Height = 20
            };

            txtBackendLog = new TextBox
            {
                Dock = DockStyle.Fill,
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.FromArgb(200, 255, 200),
                Font = new Font("Consolas", 8),
                ReadOnly = true
            };

            logPanel.Controls.Add(txtBackendLog);
            logPanel.Controls.Add(logLabel);

            this.Controls.Add(gridPanel);
            this.Controls.Add(logPanel);
            this.Controls.Add(controlPanel);
            this.Controls.Add(headerPanel);
        }

        private Button CreateButton(string text, Point location, Color backColor)
        {
            return new Button
            {
                Text = text,
                Location = location,
                Width = 140,
                Height = 30,
                BackColor = backColor,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
        }

        private void SetupDataGrid()
        {
            gridClients.Columns.Add("ID", "ID");
            gridClients.Columns.Add("Email", "Email");
            gridClients.Columns.Add("Name", "Tên");
            gridClients.Columns.Add("Status", "Trạng thái");
            gridClients.Columns.Add("Port", "Port");
            gridClients.Columns.Add("Token", "Token");
            
            gridClients.Columns["ID"].Width = 50;
            gridClients.Columns["Email"].Width = 200;
            gridClients.Columns["Name"].Width = 150;
            gridClients.Columns["Status"].Width = 150;
            gridClients.Columns["Port"].Width = 80;
            gridClients.Columns["Token"].AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        }

        private string FindFlutter()
        {
            // Tìm Flutter
            var paths = new[]
            {
                @"D:\Setup\flutter_windows_3.35.7-stable\flutter\bin\flutter.bat",
                @"C:\src\flutter\bin\flutter.bat",
                "flutter" // In PATH
            };

            foreach (var path in paths)
            {
                if (File.Exists(path) || path == "flutter")
                {
                    return path;
                }
            }

            return "flutter"; // Fallback
        }

        private async void BtnStartBackend_Click(object sender, EventArgs e)
        {
            try
            {
                btnStartBackend.Enabled = false;
                LogBackend("Starting backend server...");

                var backendPath = Path.Combine(projectPath, "backend");
                
                // Kiểm tra xem thư mục backend có tồn tại không
                if (!Directory.Exists(backendPath))
                {
                    MessageBox.Show($"Không tìm thấy thư mục backend tại:\n{backendPath}\n\n" +
                                    "Vui lòng đảm bảo Tasky Manager đang chạy trong thư mục Tasky project.",
                                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    btnStartBackend.Enabled = true;
                    return;
                }
                
                LogBackend($"Backend path: {backendPath}");
                
                var startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = "/c npm run dev",
                    WorkingDirectory = backendPath,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    StandardOutputEncoding = Encoding.UTF8,
                    StandardErrorEncoding = Encoding.UTF8
                };

                backendProcess = new Process { StartInfo = startInfo };
                backendProcess.OutputDataReceived += (s, args) => LogBackend(args.Data);
                backendProcess.ErrorDataReceived += (s, args) => LogBackend(args.Data);
                
                backendProcess.Start();
                backendProcess.BeginOutputReadLine();
                backendProcess.BeginErrorReadLine();

                // Wait for backend to start
                await Task.Delay(3000);

                // Test connection
                try
                {
                    var response = await httpClient.GetAsync($"{baseUrl}/auth/me");
                    lblStatus.Text = "✅ Backend: Running on port 4000";
                    lblStatus.ForeColor = Color.FromArgb(100, 180, 100);
                    btnStopBackend.Enabled = true;
                    LogBackend("Backend started successfully!");
                }
                catch
                {
                    lblStatus.Text = "⚠️ Backend: Starting...";
                    lblStatus.ForeColor = Color.FromArgb(255, 165, 0);
                    btnStopBackend.Enabled = true;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi khi start backend: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                btnStartBackend.Enabled = true;
            }
        }

        private void BtnStopBackend_Click(object sender, EventArgs e)
        {
            try
            {
                if (backendProcess != null && !backendProcess.HasExited)
                {
                    backendProcess.Kill(true);
                    backendProcess = null;
                }

                lblStatus.Text = "⚪ Backend: Stopped";
                lblStatus.ForeColor = Color.FromArgb(150, 150, 150);
                btnStartBackend.Enabled = true;
                btnStopBackend.Enabled = false;
                LogBackend("Backend stopped.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi khi stop backend: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private async void BtnStart_Click(object sender, EventArgs e)
        {
            try
            {
                int clientCount = (int)numClients.Value;
                btnStart.Enabled = false;
                btnStart.Visible = false;
                btnStop.Enabled = true;
                btnStop.Visible = true;

                LogBackend($"========================================");
                LogBackend($"🚀 Starting {clientCount} client(s)...");
                LogBackend($"========================================");

                // Clear existing clients
                StopAllClients();
                clients.Clear();
                gridClients.Rows.Clear();

                // Clean Flutter build cache first
                LogBackend($"🧹 Cleaning Flutter cache...");
                var appPath = Path.Combine(projectPath, "tasky_app");
                var cleanProcess = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "cmd.exe",
                        Arguments = $"/c \"{flutterPath}\" clean",
                        WorkingDirectory = appPath,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };
                cleanProcess.Start();
                cleanProcess.WaitForExit();
                LogBackend($"✅ Cache cleaned");
                LogBackend($"");

                // Start Flutter clients
                LogBackend($"📱 Launching Flutter apps...");
                for (int i = 0; i < clientCount; i++)
                {
                    var client = new ClientInstance
                    {
                        Id = i + 1,
                        Email = $"Client {i + 1}",
                        Name = $"Client {i + 1}",
                        Port = 9000 + i
                    };

                    await StartClient(client);
                    clients.Add(client);

                    var rowIndex = gridClients.Rows.Add();
                    UpdateClientRow(rowIndex, client);

                    // Đợi lâu hơn giữa các client để tránh xung đột
                    if (i < clientCount - 1)
                    {
                        LogBackend($"⏳ Đợi 5 giây trước khi start client tiếp theo...");
                        await Task.Delay(5000);
                    }
                }

                LogBackend($"");
                LogBackend($"✅ Đã start {clientCount} client(s)!");
                LogBackend($"");
                LogBackend($" Mỗi client sẽ mở trong Edge browser riêng biệt.");
                LogBackend($"   Bạn có thể đăng ký/đăng nhập tài khoản bất kỳ.");
                LogBackend($"");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                btnStart.Enabled = true;
                btnStart.Visible = true;
                btnStop.Visible = false;
            }
        }

        private async Task RegisterTestAccounts(int count)
        {
            LogBackend($"Registering {count} test accounts...");

            for (int i = 0; i < count; i++)
            {
                try
                {
                    var payload = new
                    {
                        name = $"Test User {i + 1}",
                        email = $"user{i + 1}@test.com",
                        password = "test123"
                    };

                    var json = JsonConvert.SerializeObject(payload);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");
                    
                    var response = await httpClient.PostAsync($"{baseUrl}/auth/register", content);
                    var result = await response.Content.ReadAsStringAsync();

                    if (response.IsSuccessStatusCode)
                    {
                        LogBackend($"✅ Registered: {payload.email}");
                    }
                    else
                    {
                        LogBackend($"⚠️ {payload.email} - {result}");
                    }
                }
                catch (Exception ex)
                {
                    LogBackend($"❌ Error registering user{i + 1}: {ex.Message}");
                }

                await Task.Delay(500);
            }
        }

        private Task StartClient(ClientInstance client)
        {
            try
            {
                var appPath = Path.Combine(projectPath, "tasky_app");
                
                if (!Directory.Exists(appPath))
                {
                    client.Status = $"Error: App folder not found";
                    LogBackend($"❌ Flutter app không tìm thấy tại: {appPath}");
                    return Task.CompletedTask;
                }
                
                // Sử dụng edge và mở cửa sổ riêng với port khác nhau
                var startInfo = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/k \"{flutterPath}\" run -d edge --web-port={client.Port}",
                    WorkingDirectory = appPath,
                    UseShellExecute = true, // Phải dùng true để mở terminal mới
                    CreateNoWindow = false
                };

                client.Process = Process.Start(startInfo);
                client.Status = "Starting...";
                
                LogBackend($"✅ Started Client {client.Id} on port {client.Port}");
                LogBackend($"   Đang mở Edge browser, vui lòng đợi...");
            }
            catch (Exception ex)
            {
                client.Status = $"Error: {ex.Message}";
                LogBackend($"❌ Failed to start client {client.Id}: {ex.Message}");
            }
            
            return Task.CompletedTask;
        }

        private void BtnStop_Click(object sender, EventArgs e)
        {
            StopAllClients();
            btnStart.Enabled = true;
            btnStart.Visible = true;
            btnStop.Enabled = false;
            btnStop.Visible = false;
        }

        private void StopAllClients()
        {
            foreach (var client in clients)
            {
                try
                {
                    if (client.Process != null && !client.Process.HasExited)
                    {
                        client.Process.Kill(true);
                        client.Status = "Stopped";
                    }
                }
                catch { }
            }

            LogBackend("All clients stopped.");
        }

        private void UpdateClientRow(int rowIndex, ClientInstance client)
        {
            if (gridClients.InvokeRequired)
            {
                gridClients.Invoke(() => UpdateClientRow(rowIndex, client));
                return;
            }

            var row = gridClients.Rows[rowIndex];
            row.Cells["ID"].Value = client.Id;
            row.Cells["Email"].Value = client.Email;
            row.Cells["Name"].Value = client.Name;
            row.Cells["Status"].Value = client.Status;
            row.Cells["Port"].Value = client.Port;
            row.Cells["Token"].Value = client.Token ?? "Not logged in";
        }

        private void LogBackend(string message)
        {
            if (string.IsNullOrWhiteSpace(message)) return;

            if (txtBackendLog.InvokeRequired)
            {
                txtBackendLog.Invoke(() => LogBackend(message));
                return;
            }

            txtBackendLog.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}\r\n");
            txtBackendLog.SelectionStart = txtBackendLog.Text.Length;
            txtBackendLog.ScrollToCaret();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            StopAllClients();
            
            if (backendProcess != null && !backendProcess.HasExited)
            {
                backendProcess.Kill(true);
            }

            base.OnFormClosing(e);
        }
    }

    public class ClientInstance
    {
        public int Id { get; set; }
        public string Email { get; set; } = "";
        public string Name { get; set; } = "";
        public string Status { get; set; } = "Stopped";
        public int Port { get; set; }
        public string Token { get; set; }
        public Process Process { get; set; }
    }
}
