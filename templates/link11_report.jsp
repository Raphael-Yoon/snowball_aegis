<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>공시자료 생성 - 정보보호공시</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <style>
        .report-container {
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
            text-decoration: none;
        }

        .back-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            color: white;
        }

        .report-section {
            background: white;
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }

        .section-title {
            font-size: 1.2rem;
            font-weight: 600;
            color: #1e3a5f;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e2e8f0;
        }

        .progress-check {
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 15px;
            background: #f8fafc;
            border-radius: 10px;
            margin-bottom: 15px;
        }

        .progress-check.complete {
            background: #dcfce7;
        }

        .progress-check.incomplete {
            background: #fef3c7;
        }

        .progress-check i {
            font-size: 1.5rem;
        }

        .progress-check.complete i {
            color: #16a34a;
        }

        .progress-check.incomplete i {
            color: #d97706;
        }

        .category-summary {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }

        .category-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            background: #f8fafc;
            border-radius: 10px;
        }

        .category-item .name {
            font-weight: 500;
        }

        .category-item .progress {
            font-weight: 600;
            color: #3b82f6;
            min-width: 100px;
            background: #e0f2fe;
            padding: 6px 12px;
            border-radius: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .format-options {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 20px;
        }

        .format-card {
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            padding: 25px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }

        .format-card:hover {
            border-color: #3b82f6;
            background: #eff6ff;
        }

        .format-card.selected {
            border-color: #3b82f6;
            background: #eff6ff;
        }

        .format-card i {
            font-size: 3rem;
            margin-bottom: 15px;
        }

        .format-card.excel i {
            color: #16a34a;
        }

        .format-card.pdf i {
            color: #dc2626;
        }

        .format-card.kisa i {
            color: #7c3aed;
        }

        .format-card.disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
        }

        .format-card .badge-coming-soon {
            background: #f59e0b;
            color: white;
            font-size: 0.7rem;
            padding: 2px 8px;
            border-radius: 10px;
            margin-top: 8px;
            display: inline-block;
        }

        .format-card h5 {
            margin-bottom: 10px;
        }

        .format-card p {
            color: #64748b;
            font-size: 0.9rem;
            margin: 0;
        }

        .preview-section {
            background: #f8fafc;
            border-radius: 10px;
            padding: 20px;
            max-height: 400px;
            overflow-y: auto;
        }

        .preview-category {
            margin-bottom: 20px;
        }

        .preview-category h6 {
            color: #1e3a5f;
            font-weight: 600;
            margin-bottom: 10px;
            padding-bottom: 5px;
            border-bottom: 1px solid #e2e8f0;
        }

        .preview-item {
            display: flex;
            padding: 8px 0;
            border-bottom: 1px dashed #e2e8f0;
        }

        .preview-item:last-child {
            border-bottom: none;
        }

        .preview-item .question {
            flex: 1;
            color: #475569;
        }

        .preview-item .answer {
            font-weight: 600;
            color: #1e3a5f;
            text-align: right;
            flex: 0 0 auto;
            min-width: 100px;
        }

        .generate-btn {
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 10px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }

        .generate-btn.warning {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        }

        .generate-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(59, 130, 246, 0.4);
        }

        .generate-btn:disabled {
            background: #94a3b8;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
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

        .loading-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }

        .loading-content {
            background: white;
            padding: 40px;
            border-radius: 15px;
            text-align: center;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid #e2e8f0;
            border-top-color: #3b82f6;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }

        @keyframes spin {
            to {
                transform: rotate(360deg);
            }
        }

        @media (max-width: 768px) {
            .format-options {
                grid-template-columns: 1fr;
            }

            .category-summary {
                grid-template-columns: 1fr;
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
    <div class="loading-overlay" id="loading-overlay" style="display: none;">
        <div class="loading-content">
            <div class="spinner"></div>
            <p>공시자료를 생성하고 있습니다...</p>
        </div>
    </div>

    <div class="report-container">
        <!-- 페이지 헤더 -->
        <div class="page-header">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h1 class="page-title">
                        <i class="fas fa-file-export"></i> 공시자료 생성
                    </h1>
                    <p class="mb-0 opacity-75">KISA 정보보호공시 제출용 자료를 생성합니다.</p>
                    
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
            공시자료 생성을 위해서는 <a href="{{ url_for('login') }}">로그인</a>이 필요합니다.
        </div>
        {% else %}

        <!-- 진행 상황 확인 -->
        <div class="report-section">
            <h3 class="section-title"><i class="fas fa-tasks"></i> 진행 상황 확인</h3>

            <div id="progress-check-area">
                <!-- JavaScript로 동적 생성 -->
            </div>

            <div class="category-summary" id="category-summary">
                <!-- JavaScript로 동적 생성 -->
            </div>
        </div>

        <!-- 출력 형식 선택 -->
        <div class="report-section">
            <h3 class="section-title"><i class="fas fa-file-alt"></i> 출력 형식 선택</h3>

            <div class="format-options">
                <div class="format-card excel selected" onclick="selectFormat('excel')">
                    <i class="fas fa-file-excel"></i>
                    <h5>Excel</h5>
                    <p>편집 가능한 엑셀 형식<br>(.xlsx)</p>
                </div>
                <div class="format-card pdf" onclick="selectFormat('pdf')">
                    <i class="fas fa-file-pdf"></i>
                    <h5>PDF</h5>
                    <p>인쇄용 PDF 형식<br>(.pdf)</p>
                </div>
                <div class="format-card kisa disabled">
                    <i class="fas fa-building"></i>
                    <h5>KISA 양식</h5>
                    <p>KISA 제출용 표준 양식<br>(.xlsx)</p>
                    <span class="badge-coming-soon">준비 중</span>
                </div>
            </div>
        </div>

        <!-- 미리보기 -->
        <div class="report-section">
            <h3 class="section-title"><i class="fas fa-eye"></i> 미리보기</h3>

            <div class="preview-section" id="preview-area">
                <!-- JavaScript로 동적 생성 -->
            </div>
        </div>

        <!-- 생성 버튼 -->
        <div class="text-center">
            <button class="generate-btn" id="generate-btn" onclick="generateReport()">
                <i class="fas fa-download"></i> 공시자료 생성 및 다운로드
            </button>
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

        let selectedFormat = 'excel';
        let reportData = null;

        document.addEventListener('DOMContentLoaded', function () {
            initYearSelector();
            loadProgress();
            loadPreview();
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
            loadProgress();
            loadPreview();
        }

        // 진행 상황 로드
        async function loadProgress() {
            try {
                const response = await fetch(`/link11/api/progress/${userId}/${currentYear}`);
                const data = await response.json();

                if (data.success) {
                    renderProgressCheck(data);
                    renderCategorySummary(data.categories);
                }
            } catch (error) {
                console.error('진행 상황 로드 오류:', error);
            }
        }

        // 진행 상황 체크 렌더링
        function renderProgressCheck(data) {
            const area = document.getElementById('progress-check-area');
            const progress = data.progress || {};
            const isComplete = progress.completion_rate >= 100;

            area.innerHTML = `
                <div class="progress-check ${isComplete ? 'complete' : 'incomplete'}">
                    <i class="fas ${isComplete ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
                    <div>
                        <strong>${isComplete ? '모든 질문에 답변 완료' : '미완료 질문이 있습니다'}</strong>
                        <p class="mb-0 text-muted">전체 진행률: ${progress.completion_rate || 0}% (${progress.answered_questions || 0}/${progress.total_questions || 0} 질문)</p>
                    </div>
                </div>
            `;

            // 완료되지 않아도 생성은 가능하도록 허용 (단, 경고 표시)
            const generateBtn = document.getElementById('generate-btn');
            if (generateBtn) {
                generateBtn.disabled = false;
                if (!isComplete) {
                    generateBtn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> 미완료 상태로 생성하기';
                    generateBtn.classList.add('warning');
                } else {
                    generateBtn.innerHTML = '<i class="fas fa-download"></i> 공시자료 생성 및 다운로드';
                    generateBtn.classList.remove('warning');
                }
            }
        }

        // 카테고리별 요약 렌더링
        function renderCategorySummary(categories) {
            const area = document.getElementById('category-summary');

            if (!categories || Object.keys(categories).length === 0) {
                area.innerHTML = '<p class="text-muted">카테고리 정보를 불러오는 중...</p>';
                return;
            }

            const sortedCategories = Object.entries(categories).sort((a, b) => a[1].id - b[1].id);
            area.innerHTML = sortedCategories.map(([name, c]) => `
                <div class="category-item">
                    <span class="name">${name}</span>
                    <span class="progress">${c.completed}/${c.total} 완료</span>
                </div>
            `).join('');
        }

        // 미리보기 로드
        async function loadPreview() {
            try {
                const response = await fetch('/link11/api/report/generate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        company_id: companyName,
                        year: currentYear,
                        format: 'json'
                    })
                });

                const data = await response.json();

                if (data.success) {
                    reportData = data.report;
                    renderPreview(reportData);
                }
            } catch (error) {
                console.error('미리보기 로드 오류:', error);
            }
        }

        // 미리보기 렌더링
        function renderPreview(report) {
            const area = document.getElementById('preview-area');

            if (!report || !report.categories) {
                area.innerHTML = '<p class="text-muted text-center">미리보기 데이터를 불러오는 중...</p>';
                return;
            }

            let html = '';
            const sortedReportCats = Object.entries(report.categories).sort((a, b) => a[1].id - b[1].id);
            for (const [categoryName, categoryData] of sortedReportCats) {
                html += `
                    <div class="preview-category">
                        <h6><i class="fas fa-folder"></i> ${categoryName}</h6>
                `;

                categoryData.questions.forEach(q => {
                    let value = q.value;
                    let displayValue = '-';

                    // Q3(정보보호 투자 합계)는 type이 group이지만 실제로는 숫자값이므로 number로 취급
                    const isNumericType = q.type === 'number' || q.id === 'Q3';

                    if (value !== null && value !== undefined && value !== '' && value !== '해당 없음') {
                        if (isNumericType) {
                            try {
                                const num = parseFloat(String(value).replace(/,/g, ''));
                                displayValue = !isNaN(num) ? num.toLocaleString() : value;
                            } catch (e) {
                                displayValue = value;
                            }
                        } else if (q.type === 'yes_no') {
                            const upperVal = String(value).toUpperCase();
                            displayValue = (upperVal === 'YES') ? '예' : (upperVal === 'NO' ? '아니요' : value);
                        } else if (typeof value === 'object') {
                            if (Array.isArray(value)) {
                                displayValue = value.length > 0 ? value.join(', ') : (q.type === 'checkbox' ? '미수행' : '-');
                            } else {
                                // 랭크/구성 등 객체 형태 처리
                                displayValue = Object.entries(value)
                                    .map(([k, v]) => `${k}: ${v}`)
                                    .join(' / ');
                            }
                        } else {
                            displayValue = value;
                        }
                    } else if (isNumericType) {
                        displayValue = '0';
                    }

                    html += `
                        <div class="preview-item">
                            <span class="question">${q.id}. ${q.text}</span>
                            <span class="answer" style="${(isNumericType && displayValue !== '해당 없음' && displayValue !== '-') ? 'color: #2563eb; font-family: monospace;' : ''}">
                                ${displayValue}
                            </span>
                        </div>
                    `;
                });

                html += '</div>';
            }

            area.innerHTML = html || '<p class="text-muted text-center">답변된 내용이 없습니다.</p>';
        }

        // 형식 선택
        function selectFormat(format) {
            selectedFormat = format;

            document.querySelectorAll('.format-card').forEach(card => {
                card.classList.remove('selected');
            });
            document.querySelector(`.format-card.${format}`).classList.add('selected');
        }

        // 보고서 생성
        async function generateReport() {
            document.getElementById('loading-overlay').style.display = 'flex';

            try {
                const response = await fetch('/link11/api/report/download', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        company_id: companyName,
                        year: currentYear,
                        format: selectedFormat
                    })
                });

                if (response.ok) {
                    // 파일 다운로드
                    const blob = await response.blob();
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;

                    const ext = selectedFormat === 'pdf' ? 'pdf' : 'xlsx';
                    a.download = `정보보호공시_${companyName}_${currentYear}.${ext}`;

                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    window.URL.revokeObjectURL(url);

                    showToast('공시자료가 생성되었습니다.', 'success');
                } else {
                    const data = await response.json();
                    showToast('생성 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                }
            } catch (error) {
                console.error('보고서 생성 오류:', error);
                showToast('보고서 생성 중 오류가 발생했습니다.', 'error');
            } finally {
                document.getElementById('loading-overlay').style.display = 'none';
            }
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