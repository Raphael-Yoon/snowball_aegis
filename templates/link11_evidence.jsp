<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>증빙자료 관리 - 정보보호공시</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <style>
        .evidence-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .page-header {
            background: linear-gradient(135deg, #1e3a5f 0%, #2d5a87 100%);
            color: white;
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 30px;
        }

        .page-title {
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .back-btn {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s;
        }

        .back-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            color: white;
        }

        .filter-section {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }

        .evidence-table {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }

        .evidence-table table {
            width: 100%;
            margin: 0;
        }

        .evidence-table th {
            background: #f8fafc;
            padding: 15px;
            font-weight: 600;
            color: #475569;
            border-bottom: 2px solid #e2e8f0;
        }

        .evidence-table td {
            padding: 15px;
            border-bottom: 1px solid #e2e8f0;
            vertical-align: middle;
        }

        .evidence-table tr:hover {
            background: #f8fafc;
        }

        .file-icon {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
        }

        .file-icon.pdf {
            background: #fee2e2;
            color: #dc2626;
        }

        .file-icon.excel {
            background: #dcfce7;
            color: #16a34a;
        }

        .file-icon.word {
            background: #dbeafe;
            color: #2563eb;
        }

        .file-icon.image {
            background: #fef3c7;
            color: #d97706;
        }

        .file-icon.other {
            background: #f1f5f9;
            color: #64748b;
        }

        .question-badge {
            background: #e0f2fe;
            color: #0369a1;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
        }

        .action-btn {
            padding: 6px 12px;
            border-radius: 6px;
            border: none;
            cursor: pointer;
            font-size: 0.85rem;
            transition: all 0.2s;
        }

        .action-btn.download {
            background: #dbeafe;
            color: #2563eb;
        }

        .action-btn.download:hover {
            background: #bfdbfe;
        }

        .action-btn.delete {
            background: #fee2e2;
            color: #dc2626;
        }

        .action-btn.delete:hover {
            background: #fecaca;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #64748b;
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.5;
        }

        .upload-zone {
            border: 2px dashed #cbd5e1;
            border-radius: 12px;
            padding: 40px;
            text-align: center;
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.3s;
            margin-bottom: 20px;
        }

        .upload-zone:hover {
            border-color: #3b82f6;
            background: #eff6ff;
        }

        .upload-zone i {
            font-size: 3rem;
            color: #94a3b8;
            margin-bottom: 15px;
        }

        .stats-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-box {
            background: white;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }

        .stat-box .value {
            font-size: 2rem;
            font-weight: 700;
            color: #1e3a5f;
        }

        .stat-box .label {
            color: #64748b;
            font-size: 0.9rem;
        }

        .toast-container {
            position: fixed;
            top: 80px;
            right: 20px;
            z-index: 9999;
        }

        .toast-message {
            background: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
            animation: slideIn 0.3s ease;
        }

        .toast-message.success {
            border-left: 4px solid #10b981;
        }

        .toast-message.error {
            border-left: 4px solid #ef4444;
        }

        .toast-message.warning {
            border-left: 4px solid #f59e0b;
        }

        .toast-message.info {
            border-left: 4px solid #3b82f6;
        }

        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }

            to {
                transform: translateX(0);
                opacity: 1;
            }
        }

        @media (max-width: 768px) {
            .stats-row {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        /* [윤지현] 공시 연도 선택기 - 헤더 통합 스타일 */
        .year-selector-container {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(255, 255, 255, 0.1);
            padding: 7px 14px 7px 12px;
            border-radius: 50px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            margin-top: 14px;
            transition: background 0.2s ease, border-color 0.2s ease;
        }

        .year-selector-container:hover {
            background: rgba(255, 255, 255, 0.18);
            border-color: rgba(255, 255, 255, 0.4);
        }

        .year-label {
            color: rgba(255, 255, 255, 0.7);
            font-weight: 500;
            font-size: 0.78rem;
            white-space: nowrap;
            letter-spacing: 0.02em;
        }

        .year-select {
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            background: transparent;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='rgba(255,255,255,0.6)' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 2px center;
            background-size: 11px;
            border: none;
            color: white;
            font-weight: 700;
            font-size: 0.88rem;
            cursor: pointer;
            outline: none;
            padding-right: 18px;
            font-family: 'JetBrains Mono', 'Pretendard', sans-serif;
            letter-spacing: -0.02em;
        }

        .year-select option {
            background: #1e293b;
            color: white;
            font-weight: 600;
        }
    </style>
</head>

<body>
    {% include 'navi.jsp' %}

    <div class="toast-container" id="toast-container"></div>

    <div class="evidence-container">
        <!-- 페이지 헤더 -->
        <div class="page-header">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h1 class="page-title">
                        <i class="fas fa-file-alt"></i> 증빙자료 관리
                    </h1>
                    <p class="mb-0 opacity-75">정보보호공시를 위한 증빙자료를 관리합니다.</p>
                    
                    <!-- 대상 연도 선택기 -->
                    <div class="year-selector-container">
                        <span class="year-label"><i class="fas fa-calendar-check me-2"></i>공시 대상 연도:</span>
                        <select class="year-select" id="disclosure-year-select" onchange="changeDisclosureYear()">
                        </select>
                    </div>
                </div>
                <a href="/link11" class="back-btn">
                    <i class="fas fa-arrow-left"></i> 공시 현황으로 돌아가기
                </a>
            </div>
        </div>

        {% if not is_logged_in %}
        <div class="alert alert-warning text-center">
            <i class="fas fa-exclamation-triangle"></i>
            증빙자료 관리를 위해서는 <a href="{{ url_for('login') }}">로그인</a>이 필요합니다.
        </div>
        {% else %}

        <!-- 통계 -->
        <div class="stats-row">
            <div class="stat-box">
                <div class="value" id="stat-total">0</div>
                <div class="label">전체 파일</div>
            </div>
            <div class="stat-box">
                <div class="value" id="stat-questions">0</div>
                <div class="label">연결된 질문</div>
            </div>
            <div class="stat-box">
                <div class="value" id="stat-size">0 MB</div>
                <div class="label">총 용량</div>
            </div>
            <div class="stat-box">
                <div class="value" id="stat-recent">0</div>
                <div class="label">최근 7일 업로드</div>
            </div>
        </div>

        <!-- 파일 업로드 영역 -->
        <div class="upload-zone" onclick="document.getElementById('file-input').click()">
            <i class="fas fa-cloud-upload-alt"></i>
            <h5>파일을 드래그하거나 클릭하여 업로드</h5>
            <p class="text-muted mb-0">PDF, Word, Excel, 이미지 파일 지원 (최대 100MB)</p>
            <input type="file" id="file-input" style="display: none;" multiple onchange="handleFileUpload(this.files)">
        </div>

        <!-- 필터 -->
        <div class="filter-section">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">카테고리</label>
                    <select class="form-select" id="filter-category" onchange="loadEvidence()">
                        <option value="">전체</option>
                        <option value="정보보호 투자 현황">투자 현황</option>
                        <option value="정보보호 인력 현황">인력 현황</option>
                        <option value="정보보호 관련 인증">인증</option>
                        <option value="정보보호 관련 활동">활동</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">파일 유형</label>
                    <select class="form-select" id="filter-type" onchange="loadEvidence()">
                        <option value="">전체</option>
                        <option value="pdf">PDF</option>
                        <option value="excel">Excel</option>
                        <option value="word">Word</option>
                        <option value="image">이미지</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label">검색</label>
                    <input type="text" class="form-control" id="filter-search" placeholder="파일명 검색..."
                        onkeyup="loadEvidence()">
                </div>
                <div class="col-md-2 d-flex align-items-end">
                    <button class="btn btn-outline-secondary w-100" onclick="resetFilters()">
                        <i class="fas fa-redo"></i> 초기화
                    </button>
                </div>
            </div>
        </div>

        <!-- 증빙자료 목록 -->
        <div class="evidence-table">
            <table>
                <thead>
                    <tr>
                        <th style="width: 50px;"></th>
                        <th>파일명</th>
                        <th>연결 질문</th>
                        <th>증빙 유형</th>
                        <th>크기</th>
                        <th>업로드일</th>
                        <th style="width: 120px;">작업</th>
                    </tr>
                </thead>
                <tbody id="evidence-list">
                    <!-- JavaScript로 동적 생성 -->
                </tbody>
            </table>
        </div>

        {% endif %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const userId = {{ user_info.user_id if user_info else 0 }};
        const companyName = '{{ user_info.company_name if user_info else "default" }}';
        
        // [김유신] 실무 사이클 반영 지능형 연도 초기화
        const now = new Date();
        const defaultYear = now.getMonth() < 6 ? now.getFullYear() - 1 : now.getFullYear();
        let currentYear = defaultYear;

        let evidenceList = [];

        document.addEventListener('DOMContentLoaded', function () {
            initYearSelector();
            loadEvidence();
            loadStats();
        });

        function initYearSelector() {
            const select = document.getElementById('disclosure-year-select');
            if (!select) return;
            const currentActualYear = new Date().getFullYear();
            for (let y = currentActualYear; y >= currentActualYear - 4; y--) {
                const option = document.createElement('option');
                option.value = y;
                option.textContent = `${y}년`;
                if (y === currentYear) option.selected = true;
                select.appendChild(option);
            }
        }

        async function changeDisclosureYear() {
            const select = document.getElementById('disclosure-year-select');
            currentYear = parseInt(select.value);
            showToast(`${currentYear}년 공시로 전환되었습니다.`, 'info');
            loadEvidence();
            loadStats();
        }

        // 증빙자료 목록 로드
        async function loadEvidence() {
            try {
                const category = document.getElementById('filter-category').value;
                const type = document.getElementById('filter-type').value;
                const search = document.getElementById('filter-search').value;

                let url = `/link11/api/evidence/${userId}/${currentYear}`;
                const params = new URLSearchParams();
                if (category) params.append('category', category);
                if (type) params.append('type', type);
                if (search) params.append('search', search);
                if (params.toString()) url += '?' + params.toString();

                const response = await fetch(url);
                const data = await response.json();

                if (data.success) {
                    evidenceList = data.evidence;
                    renderEvidence();
                }
            } catch (error) {
                console.error('증빙자료 로드 오류:', error);
            }
        }

        // 통계 로드
        async function loadStats() {
            try {
                const response = await fetch(`/link11/api/evidence/stats/${userId}/${currentYear}`);
                const data = await response.json();

                if (data.success) {
                    document.getElementById('stat-total').textContent = data.stats.total || 0;
                    document.getElementById('stat-questions').textContent = data.stats.questions || 0;
                    document.getElementById('stat-size').textContent = formatSize(data.stats.total_size || 0);
                    document.getElementById('stat-recent').textContent = data.stats.recent || 0;
                }
            } catch (error) {
                console.error('통계 로드 오류:', error);
            }
        }

        // 증빙자료 목록 렌더링
        function renderEvidence() {
            const tbody = document.getElementById('evidence-list');

            if (evidenceList.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="7">
                            <div class="empty-state">
                                <i class="fas fa-folder-open"></i>
                                <h5>등록된 증빙자료가 없습니다</h5>
                                <p>위의 업로드 영역을 통해 파일을 추가해주세요.</p>
                            </div>
                        </td>
                    </tr>
                `;
                return;
            }

            tbody.innerHTML = evidenceList.map(e => `
                <tr>
                    <td>
                        <div class="file-icon ${getFileClass(e.file_name)}">
                            <i class="${getFileIcon(e.file_name)}"></i>
                        </div>
                    </td>
                    <td>
                        <strong>${e.original_filename || e.file_name}</strong>
                    </td>
                    <td>
                        <span class="question-badge">${e.question_id || '-'}</span>
                    </td>
                    <td>${e.evidence_type || '-'}</td>
                    <td>${formatSize(e.file_size)}</td>
                    <td>${formatDate(e.created_at)}</td>
                    <td>
                        <button class="action-btn download" onclick="downloadFile('${e.id}')" title="다운로드">
                            <i class="fas fa-download"></i>
                        </button>
                        <button class="action-btn delete" onclick="deleteFile('${e.id}')" title="삭제">
                            <i class="fas fa-trash"></i>
                        </button>
                    </td>
                </tr>
            `).join('');
        }

        // 파일 업로드 처리
        async function handleFileUpload(files) {
            for (const file of files) {
                const formData = new FormData();
                formData.append('file', file);
                formData.append('year', currentYear);
                formData.append('question_id', '');
                formData.append('evidence_type', '기타');

                try {
                    const response = await fetch('/link11/api/evidence', {
                        method: 'POST',
                        body: formData
                    });

                    const data = await response.json();
                    if (data.success) {
                        showToast(`${file.name} 업로드 완료`, 'success');
                    } else {
                        showToast(`${file.name} 업로드 실패: ${data.message}`, 'error');
                    }
                } catch (error) {
                    showToast(`${file.name} 업로드 오류`, 'error');
                }
            }

            loadEvidence();
            loadStats();
            document.getElementById('file-input').value = '';
        }

        // 파일 다운로드
        async function downloadFile(evidenceId) {
            window.open(`/link11/api/evidence/download/${evidenceId}`, '_blank');
        }

        // 파일 삭제
        async function deleteFile(evidenceId) {
            if (!confirm('이 파일을 삭제하시겠습니까?')) return;

            try {
                const response = await fetch(`/link11/api/evidence/${evidenceId}`, {
                    method: 'DELETE'
                });

                const data = await response.json();
                if (data.success) {
                    showToast('파일이 삭제되었습니다.', 'success');
                    loadEvidence();
                    loadStats();
                } else {
                    showToast('삭제 실패: ' + data.message, 'error');
                }
            } catch (error) {
                showToast('삭제 중 오류가 발생했습니다.', 'error');
            }
        }

        // 필터 초기화
        function resetFilters() {
            document.getElementById('filter-category').value = '';
            document.getElementById('filter-type').value = '';
            document.getElementById('filter-search').value = '';
            loadEvidence();
        }

        // 유틸리티 함수들
        function getFileClass(filename) {
            const ext = filename.split('.').pop().toLowerCase();
            if (ext === 'pdf') return 'pdf';
            if (['xls', 'xlsx'].includes(ext)) return 'excel';
            if (['doc', 'docx'].includes(ext)) return 'word';
            if (['jpg', 'jpeg', 'png', 'gif'].includes(ext)) return 'image';
            return 'other';
        }

        function getFileIcon(filename) {
            const ext = filename.split('.').pop().toLowerCase();
            if (ext === 'pdf') return 'fas fa-file-pdf';
            if (['xls', 'xlsx'].includes(ext)) return 'fas fa-file-excel';
            if (['doc', 'docx'].includes(ext)) return 'fas fa-file-word';
            if (['jpg', 'jpeg', 'png', 'gif'].includes(ext)) return 'fas fa-file-image';
            return 'fas fa-file';
        }

        function formatSize(bytes) {
            if (!bytes || bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
        }

        function formatDate(dateStr) {
            if (!dateStr) return '-';
            const date = new Date(dateStr);
            return date.toLocaleDateString('ko-KR');
        }

        function showToast(message, type = 'info') {
            const container = document.getElementById('toast-container');
            const toast = document.createElement('div');
            toast.className = `toast-message ${type}`;

            const icons = {
                success: 'fa-check-circle',
                error: 'fa-exclamation-circle',
                warning: 'fa-exclamation-triangle',
                info: 'fa-info-circle'
            };

            toast.innerHTML = `<i class="fas ${icons[type] || icons.info}"></i><span>${message}</span>`;
            container.appendChild(toast);

            setTimeout(() => toast.remove(), 3000);
        }
    </script>
</body>

</html>