<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - AI 분석 결과 조회</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <style>
        /* Link10 페이지 전용 스타일 */
        .link10-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px;
        }

        .page-header {
            margin-bottom: 40px;
            text-align: center;
        }

        .page-title {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--primary-color);
            margin-bottom: 10px;
            letter-spacing: -0.03em;
        }

        .page-description {
            color: #6c757d;
            font-size: 1.1rem;
        }

        .section-header {
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
        }

        .section-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--primary-color);
            margin: 0;
            letter-spacing: -0.02em;
        }

        /* 시장별 섹션 컨테이너 */
        .market-section {
            margin-bottom: 50px;
        }

        .market-section:last-child {
            margin-bottom: 0;
        }

        .market-section-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 25px;
            padding-bottom: 12px;
            border-bottom: 3px solid var(--border-color);
        }

        .market-icon {
            width: 45px;
            height: 45px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            font-weight: 700;
            color: white;
        }

        .market-icon.kospi {
            background: linear-gradient(135deg, #3b82f6 0%, #1e40af 100%);
        }

        .market-icon.kosdaq {
            background: linear-gradient(135deg, #ec4899 0%, #be185d 100%);
        }

        .market-icon.all {
            background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%);
        }

        .market-section-title {
            font-size: 1.6rem;
            font-weight: 700;
            color: var(--text-color);
            margin: 0;
            letter-spacing: -0.02em;
        }

        .market-count {
            font-size: 0.9rem;
            color: #6c757d;
            font-weight: 500;
            margin-left: auto;
        }

        /* 결과 카드 그리드 */
        .results-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 25px;
        }

        .result-card {
            background: white;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 25px;
            transition: all 0.3s ease;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        }

        .result-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
            border-color: var(--secondary-color);
        }

        .result-header {
            display: flex;
            align-items: flex-start;
            gap: 15px;
            margin-bottom: 20px;
        }

        .result-icon {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
        }

        .result-info {
            flex: 1;
            min-width: 0;
        }

        .result-filename {
            font-weight: 700;
            font-size: 1.1rem;
            color: var(--text-color);
            margin-bottom: 8px;
            word-break: break-word;
            letter-spacing: -0.02em;
        }

        .result-meta {
            display: flex;
            gap: 15px;
            font-size: 0.9rem;
            color: #6c757d;
        }

        .result-meta span {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .result-badges {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            flex-wrap: wrap;
        }

        .badge-tag {
            padding: 4px 12px;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        .badge-market {
            background-color: #e0f2fe;
            color: #0369a1;
        }

        .badge-market.kospi {
            background-color: #dbeafe;
            color: #1e40af;
        }

        .badge-market.kosdaq {
            background-color: #fce7f3;
            color: #be185d;
        }

        .badge-market.all {
            background-color: #f3e8ff;
            color: #7c3aed;
        }

        .badge-count {
            background-color: #fef3c7;
            color: #92400e;
        }

        .result-actions {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }

        .result-btn {
            padding: 10px 16px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 0.95rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            border: 2px solid transparent;
            display: inline-block;
            letter-spacing: -0.01em;
        }

        .result-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .btn-download {
            background-color: #10b981;
            color: white;
        }

        .btn-download:hover {
            background-color: #059669;
            color: white;
        }

        .btn-ai {
            background-color: #8b5cf6;
            color: white;
        }

        .btn-ai:hover {
            background-color: #7c3aed;
            color: white;
        }

        .btn-ai:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .btn-drive {
            background-color: #4285f4;
            color: white;
        }

        .btn-drive:hover {
            background-color: #3367d6;
            color: white;
        }

        /* AI Modal - 라이트 테마 스타일 */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            z-index: 2000;
            justify-content: center;
            align-items: center;
            padding: 40px;
        }

        .modal-content {
            background: white;
            border-radius: 16px;
            width: 100%;
            max-width: 1000px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
        }

        .modal-header {
            padding: 24px 32px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 16px 16px 0 0;
        }

        .modal-header h2 {
            margin: 0;
            font-size: 1.4rem;
            font-weight: 700;
            color: white;
            letter-spacing: -0.02em;
        }

        .modal-body {
            padding: 32px;
            overflow-y: auto;
            flex: 1;
            background: white;
        }

        .modal-footer {
            padding: 16px 32px !important;
            border-top: 1px solid #e5e7eb !important;
            display: flex !important;
            justify-content: flex-end !important;
            gap: 12px !important;
            background: #f9fafb !important;
            border-radius: 0 0 16px 16px !important;
        }

        .modal-footer button,
        .modal-footer .btn,
        .modal-footer .btn-secondary {
            padding: 10px 24px !important;
            border-radius: 8px !important;
            font-weight: 600 !important;
            background: #6366f1 !important;
            border: none !important;
            color: white !important;
            cursor: pointer !important;
            transition: background 0.2s !important;
        }

        .modal-footer button:hover,
        .modal-footer .btn:hover,
        .modal-footer .btn-secondary:hover {
            background: #4f46e5 !important;
        }

        .close-modal {
            font-size: 28px;
            cursor: pointer;
            color: rgba(255, 255, 255, 0.8);
            line-height: 1;
            transition: color 0.2s;
        }

        .close-modal:hover {
            color: white;
        }

        /* 로딩 스피너 */
        .loading-ai {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 60px;
        }

        .ai-spinner {
            width: 50px;
            height: 50px;
            border: 4px solid #e5e7eb;
            border-top-color: #6366f1;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to {
                transform: rotate(360deg);
            }
        }

        .loading-ai p {
            margin-top: 20px;
            color: #6b7280;
            font-size: 15px;
        }

        /* AI 마크다운 본문 - 라이트테마 */
        .ai-markdown-body {
            line-height: 1.8;
            color: #1f2937;
            font-size: 15px;
        }

        /* 구글 문서 HTML 스타일 초기화 */
        .ai-markdown-body * {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans KR', sans-serif !important;
        }

        /* 제목 스타일 */
        .ai-markdown-body h1,
        .ai-markdown-body h2,
        .ai-markdown-body h3,
        .ai-markdown-body h4,
        .ai-markdown-body p.title,
        .ai-markdown-body p.subtitle {
            color: #1e293b;
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 700;
            line-height: 1.4;
        }

        .ai-markdown-body h1,
        .ai-markdown-body p.title {
            font-size: 1.75rem;
            margin-top: 0;
            color: #4338ca;
            letter-spacing: -0.03em;
        }

        .ai-markdown-body h2,
        .ai-markdown-body p.subtitle {
            font-size: 1.4rem;
            margin-top: 32px;
            padding-bottom: 8px;
            border-bottom: 2px solid #e5e7eb;
            color: #4338ca;
            letter-spacing: -0.02em;
        }

        .ai-markdown-body h3 {
            font-size: 1.2rem;
            color: #6366f1;
            letter-spacing: -0.02em;
        }

        .ai-markdown-body h4 {
            font-size: 1.05rem;
            letter-spacing: -0.01em;
        }

        /* 단락 */
        .ai-markdown-body p {
            margin-bottom: 16px;
            line-height: 1.8;
        }

        /* 리스트 */
        .ai-markdown-body ul,
        .ai-markdown-body ol {
            margin-bottom: 16px;
            padding-left: 24px;
            line-height: 1.8;
        }

        .ai-markdown-body li {
            margin-bottom: 8px;
        }

        /* 테이블 스타일 - 라이트테마 */
        .ai-markdown-body table {
            width: 100% !important;
            border-collapse: collapse;
            margin-bottom: 24px;
            font-size: 14px;
            table-layout: fixed !important;
        }

        .ai-markdown-body th,
        .ai-markdown-body td {
            padding: 6px 10px !important;
            border: 1px solid #e5e7eb;
            text-align: left;
            vertical-align: top;
            word-wrap: break-word !important;
            word-break: break-word !important;
            overflow-wrap: break-word !important;
            white-space: normal !important;
            line-height: 1.4 !important;
        }

        .ai-markdown-body th {
            background: #f8fafc !important;
            color: #1e293b !important;
            font-weight: 700;
            padding: 8px 10px !important;
            line-height: 1.3 !important;
        }

        /* 구글 문서 HTML의 인라인 스타일 강제 덮어쓰기 */
        .ai-markdown-body th[style],
        .ai-markdown-body td[style] {
            padding: 6px 10px !important;
            line-height: 1.4 !important;
        }

        .ai-markdown-body th[style] {
            padding: 8px 10px !important;
            line-height: 1.3 !important;
        }

        /* 테이블 셀 내부의 모든 요소 여백 초기화 */
        .ai-markdown-body th *,
        .ai-markdown-body td * {
            margin: 0 !important;
            padding: 0 !important;
            line-height: 1.4 !important;
        }

        .ai-markdown-body th p,
        .ai-markdown-body td p,
        .ai-markdown-body th span,
        .ai-markdown-body td span {
            margin: 0 !important;
            padding: 0 !important;
            line-height: 1.4 !important;
            display: inline !important;
        }

        .ai-markdown-body th div,
        .ai-markdown-body td div {
            margin: 0 !important;
            padding: 0 !important;
            line-height: 1.4 !important;
        }

        /* 테이블 셀 내부의 br 태그 숨기기 */
        .ai-markdown-body th br,
        .ai-markdown-body td br {
            display: none !important;
        }

        /* 빈 p 태그 숨기기 */
        .ai-markdown-body th p:empty,
        .ai-markdown-body td p:empty {
            display: none !important;
        }

        .ai-markdown-body tbody tr:hover {
            background: #f9fafb;
        }

        /* 강조 텍스트 */
        .ai-markdown-body strong,
        .ai-markdown-body b {
            color: #1e293b;
            font-weight: 700;
        }

        /* 테이블 인라인 스타일 강제 덮어쓰기 */
        .ai-markdown-body table,
        .ai-markdown-body table[style] {
            width: 100% !important;
            max-width: 100% !important;
            table-layout: fixed !important;
        }

        /* 컬럼 너비 설정 - 비율로 지정 */
        .ai-markdown-body th:first-child,
        .ai-markdown-body td:first-child {
            width: 12% !important;
            text-align: center;
        }

        .ai-markdown-body th:nth-child(2),
        .ai-markdown-body td:nth-child(2) {
            width: 15% !important;
        }

        .ai-markdown-body th:nth-child(3),
        .ai-markdown-body td:nth-child(3) {
            width: 25% !important;
        }

        .ai-markdown-body th:nth-child(4),
        .ai-markdown-body td:nth-child(4) {
            width: 48% !important;
        }

        /* 여백 조정 */
        .ai-markdown-body > *:first-child {
            margin-top: 0;
        }

        .ai-markdown-body > *:last-child {
            margin-bottom: 0;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.3;
        }

        @media (max-width: 768px) {
            .results-grid {
                grid-template-columns: 1fr;
            }

            .result-actions {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>
    {% include 'navi.jsp' %}

    <!-- AI Analysis Modal -->
    <div id="aiModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>🤖 AI 투자 리포트</h2>
                <span class="close-modal" onclick="closeAiModal()">&times;</span>
            </div>
            <div id="aiResultContent" class="modal-body">
                <div class="loading-ai">
                    <div class="ai-spinner"></div>
                    <p>AI가 분석 중입니다...</p>
                </div>
            </div>
            <div class="modal-footer">
                <button onclick="closeAiModal()">닫기</button>
            </div>
        </div>
    </div>

    <!-- Email Input Modal -->
    <div id="emailModal" class="modal">
        <div class="modal-content" style="max-width: 500px;">
            <div class="modal-header">
                <h2>📧 이메일로 리포트 전송</h2>
                <span class="close-modal" onclick="closeEmailModal()">&times;</span>
            </div>
            <div class="modal-body">
                <p style="color: #6b7280; margin-bottom: 20px;">AI 분석 리포트를 받으실 이메일 주소를 입력해주세요.</p>
                <div style="margin-bottom: 20px;">
                    <label for="recipientEmail" style="display: block; margin-bottom: 8px; color: #374151; font-weight: 600;">이메일 주소</label>
                    <input type="email" id="recipientEmail" placeholder="example@email.com" required
                           style="width: 100%; padding: 12px 16px; background: white; border: 1px solid #d1d5db; border-radius: 8px; color: #1f2937; font-size: 15px;">
                    <div id="emailError" style="display: none; color: #ef4444; font-size: 13px; margin-top: 8px;">
                        올바른 이메일 주소를 입력해주세요.
                    </div>
                </div>
                <div id="sendingStatus" style="display: none; padding: 12px 16px; background: #eff6ff; border-radius: 8px; color: #3b82f6;">
                    <div class="ai-spinner" style="width: 20px; height: 20px; border-width: 2px; display: inline-block; vertical-align: middle; margin-right: 10px;"></div>
                    이메일을 전송하는 중입니다...
                </div>
            </div>
            <div class="modal-footer">
                <button onclick="closeEmailModal()" style="background: #e5e7eb !important; color: #374151 !important;">취소</button>
                <button onclick="sendReportByEmail()">📤 전송</button>
            </div>
        </div>
    </div>

    <div class="link10-container">
        <div class="page-header">
            <h1 class="page-title">
                <i class="fas fa-chart-line"></i> AI 분석 결과 조회
            </h1>
        </div>

        <div id="resultsList">
            <div class="empty-state">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">불러오는 중...</span>
                </div>
                <p class="mt-3">목록을 불러오는 중...</p>
            </div>
        </div>
    </div>

    <script>
        let currentFilename = null; // 현재 열려있는 리포트의 파일명
        const isLoggedIn = {{ 'true' if is_logged_in else 'false' }};

        window.onload = function () {
            loadResults();
        };

        function loadResults() {
            const resultsList = document.getElementById('resultsList');
            resultsList.innerHTML = `
                <div class="empty-state">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">불러오는 중...</span>
                    </div>
                    <p class="mt-3">목록을 불러오는 중...</p>
                </div>
            `;

            fetch('/link10/api/results')
                .then(response => response.json())
                .then(files => {
                    // AI 분석이 있는 파일만 필터링
                    const filesWithAi = files.filter(file => file.has_ai);

                    if (filesWithAi.length === 0) {
                        resultsList.innerHTML = `
                            <div class="empty-state">
                                <i class="fas fa-inbox"></i>
                                <h3>AI 분석 결과가 없습니다</h3>
                                <p>Trade 프로젝트에서 AI 분석을 실행하면 여기에 표시됩니다.</p>
                            </div>
                        `;
                        return;
                    }

                    // 파일 정보 파싱 및 그룹화
                    const parsedFiles = filesWithAi.map(file => {
                        const fileNameParts = file.filename.replace('.xlsx', '').split('_');
                        let market = 'UNKNOWN';
                        let marketLabel = file.filename;
                        let marketClass = '';
                        let countLabel = '';
                        let displayTitle = file.filename;
                        let collectionDate = '';

                        if (fileNameParts.length >= 4) {
                            market = fileNameParts[0].toUpperCase();
                            const count = fileNameParts[1];
                            const dateStr = fileNameParts[2];
                            const timeStr = fileNameParts[3];

                            // 시장 라벨
                            if (market === 'KOSPI') {
                                marketLabel = 'KOSPI';
                                marketClass = 'kospi';
                            } else if (market === 'KOSDAQ') {
                                marketLabel = 'KOSDAQ';
                                marketClass = 'kosdaq';
                            } else if (market === 'ALL') {
                                marketLabel = '전체시장';
                                marketClass = 'all';
                            }

                            // 종목 개수 라벨
                            if (count === 'all') {
                                countLabel = '전체 종목';
                            } else if (count.startsWith('top')) {
                                const num = count.replace('top', '');
                                countLabel = `상위 ${num}개`;
                            }

                            // 제목 생성
                            if (marketLabel && countLabel) {
                                displayTitle = `${marketLabel} ${countLabel} 분석`;
                            }

                            // 수집 일자 포맷팅
                            if (dateStr && dateStr.length === 8) {
                                const year = dateStr.substring(0, 4);
                                const month = dateStr.substring(4, 6);
                                const day = dateStr.substring(6, 8);
                                collectionDate = `${year}-${month}-${day}`;
                            }
                        }

                        return {
                            ...file,
                            market,
                            marketLabel,
                            marketClass,
                            countLabel,
                            displayTitle,
                            collectionDate
                        };
                    });

                    // 시장별로 그룹화
                    const groupedByMarket = {
                        'KOSPI': [],
                        'KOSDAQ': [],
                        'ALL': [],
                        'UNKNOWN': []
                    };

                    parsedFiles.forEach(file => {
                        if (groupedByMarket[file.market]) {
                            groupedByMarket[file.market].push(file);
                        } else {
                            groupedByMarket['UNKNOWN'].push(file);
                        }
                    });

                    // 각 시장 내에서 최신순으로 정렬
                    Object.keys(groupedByMarket).forEach(market => {
                        groupedByMarket[market].sort((a, b) => {
                            return (b.created_at || '').localeCompare(a.created_at || '');
                        });
                    });

                    // HTML 생성
                    let html = '';
                    const marketOrder = ['ALL', 'KOSPI', 'KOSDAQ']; // 전체 -> KOSPI -> KOSDAQ 순서
                    const marketIcons = {
                        'KOSPI': '📈',
                        'KOSDAQ': '📊',
                        'ALL': '🌐'
                    };

                    marketOrder.forEach(marketKey => {
                        const marketFiles = groupedByMarket[marketKey];
                        if (marketFiles.length === 0) return;

                        const firstFile = marketFiles[0];
                        const marketLabel = firstFile.marketLabel;
                        const marketClass = firstFile.marketClass;

                        html += `
                            <div class="market-section">
                                <div class="market-section-header">
                                    <div class="market-icon ${marketClass}">
                                        ${marketIcons[marketKey] || '📄'}
                                    </div>
                                    <h2 class="market-section-title">${marketLabel}</h2>
                                    <span class="market-count">${marketFiles.length}개 분석</span>
                                </div>
                                <div class="results-grid">
                                    ${marketFiles.map(file => `
                                        <div class="result-card">
                                            <div class="result-header">
                                                <div class="result-icon">
                                                    <i class="fas fa-chart-line" style="color: white;"></i>
                                                </div>
                                                <div class="result-info">
                                                    <div class="result-filename">${file.displayTitle}</div>
                                                    <div class="result-meta">
                                                        ${file.collectionDate ? `<span><i class="far fa-calendar-alt"></i> 데이터 수집: ${file.collectionDate}</span>` : ''}
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="result-actions">
                                                <button onclick="viewAiReport('${file.filename}')" class="result-btn btn-ai">
                                                    <i class="fas fa-robot"></i> AI 리포트 보기
                                                </button>
                                                <button onclick="handleReportSend('${file.filename}')" class="result-btn btn-download">
                                                    <i class="fas fa-paper-plane"></i> AI 리포트 전송
                                                </button>
                                            </div>
                                        </div>
                                    `).join('')}
                                </div>
                            </div>
                        `;
                    });

                    // UNKNOWN 시장 처리 (있는 경우)
                    if (groupedByMarket['UNKNOWN'].length > 0) {
                        html += `
                            <div class="market-section">
                                <div class="market-section-header">
                                    <div class="market-icon" style="background: linear-gradient(135deg, #64748b 0%, #475569 100%);">
                                        📄
                                    </div>
                                    <h2 class="market-section-title">기타</h2>
                                    <span class="market-count">${groupedByMarket['UNKNOWN'].length}개 분석</span>
                                </div>
                                <div class="results-grid">
                                    ${groupedByMarket['UNKNOWN'].map(file => `
                                        <div class="result-card">
                                            <div class="result-header">
                                                <div class="result-icon">
                                                    <i class="fas fa-chart-line" style="color: white;"></i>
                                                </div>
                                                <div class="result-info">
                                                    <div class="result-filename">${file.displayTitle}</div>
                                                    <div class="result-meta">
                                                        ${file.collectionDate ? `<span><i class="far fa-calendar-alt"></i> 데이터 수집: ${file.collectionDate}</span>` : ''}
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="result-actions">
                                                <button onclick="viewAiReport('${file.filename}')" class="result-btn btn-ai">
                                                    <i class="fas fa-robot"></i> AI 리포트 보기
                                                </button>
                                                <button onclick="handleReportSend('${file.filename}')" class="result-btn btn-download">
                                                    <i class="fas fa-paper-plane"></i> AI 리포트 전송
                                                </button>
                                            </div>
                                        </div>
                                    `).join('')}
                                </div>
                            </div>
                        `;
                    }

                    resultsList.innerHTML = html;
                })
                .catch(error => {
                    console.error('결과 목록 로드 실패:', error);
                    resultsList.innerHTML = `
                        <div class="empty-state">
                            <i class="fas fa-exclamation-triangle" style="color: #dc3545;"></i>
                            <h3>목록을 불러오는데 실패했습니다</h3>
                            <p style="color: #dc3545;">${error.message || '서버 오류가 발생했습니다.'}</p>
                            <button class="btn btn-primary mt-3" onclick="loadResults()">
                                <i class="fas fa-redo"></i> 다시 시도
                            </button>
                        </div>
                    `;
                });
        }

        function viewAiReport(filename) {
            const modal = document.getElementById('aiModal');
            const content = document.getElementById('aiResultContent');

            content.innerHTML = `
                <div class="text-center">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">불러오는 중...</span>
                    </div>
                    <p class="mt-3 text-muted">리포트를 불러오는 중...</p>
                </div>
            `;
            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden';

            fetch(`/link10/api/ai_result/${filename}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // HTML을 직접 렌더링 (구글 문서에서 HTML로 export)
                        content.innerHTML = `<div class="ai-markdown-body">${data.result}</div>`;
                    } else {
                        content.innerHTML = `
                            <div class="alert alert-warning" role="alert">
                                <i class="fas fa-exclamation-circle"></i>
                                <strong>알림:</strong> ${data.message}
                            </div>
                        `;
                    }
                })
                .catch(error => {
                    content.innerHTML = `
                        <div class="alert alert-danger" role="alert">
                            <i class="fas fa-times-circle"></i>
                            <strong>오류:</strong> ${error.message || '리포트를 불러오는 중 오류가 발생했습니다.'}
                        </div>
                    `;
                });
        }

        function downloadReport(format) {
            if (!currentFilename) {
                alert('다운로드할 리포트가 선택되지 않았습니다.');
                return;
            }

            // 다운로드 URL 생성 (PDF 형식 고정)
            const downloadUrl = `/link10/api/download_report/${currentFilename}?format=pdf`;

            // 다운로드 시작
            window.location.href = downloadUrl;

            // Toast 메시지 표시 (Bootstrap Toast 사용)
            const toastHtml = `
                <div class="position-fixed bottom-0 end-0 p-3" style="z-index: 11">
                    <div class="toast show" role="alert">
                        <div class="toast-header">
                            <i class="fas fa-download text-success me-2"></i>
                            <strong class="me-auto">다운로드 시작</strong>
                            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
                        </div>
                        <div class="toast-body">
                            PDF 형식으로 다운로드를 시작합니다.
                        </div>
                    </div>
                </div>
            `;

            // Toast를 body에 추가
            const toastContainer = document.createElement('div');
            toastContainer.innerHTML = toastHtml;
            document.body.appendChild(toastContainer);

            // 3초 후 Toast 제거
            setTimeout(() => {
                toastContainer.remove();
            }, 3000);
        }

        function closeAiModal() {
            document.getElementById('aiModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        function closeEmailModal() {
            document.getElementById('emailModal').style.display = 'none';
            document.getElementById('recipientEmail').value = '';
            document.getElementById('emailError').style.display = 'none';
            document.getElementById('sendingStatus').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        function showToast(type, title, message) {
            // type: 'success', 'danger', 'warning', 'info'
            const iconMap = {
                'success': 'fa-check-circle',
                'danger': 'fa-times-circle',
                'warning': 'fa-exclamation-triangle',
                'info': 'fa-info-circle'
            };

            const icon = iconMap[type] || 'fa-info-circle';

            const toastHtml = `
                <div class="position-fixed bottom-0 end-0 p-3" style="z-index: 11">
                    <div class="toast show" role="alert">
                        <div class="toast-header">
                            <i class="fas ${icon} text-${type} me-2"></i>
                            <strong class="me-auto">${title}</strong>
                            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
                        </div>
                        <div class="toast-body">
                            ${message}
                        </div>
                    </div>
                </div>
            `;

            const toastContainer = document.createElement('div');
            toastContainer.innerHTML = toastHtml;
            document.body.appendChild(toastContainer);

            // 3초 후 Toast 제거
            setTimeout(() => {
                toastContainer.remove();
            }, 3000);
        }

        function handleReportSend(filename) {
            currentFilename = filename;

            if (isLoggedIn) {
                // 로그인한 경우: 바로 다운로드
                window.location.href = `/link10/api/download_report/${filename}?format=pdf`;
            } else {
                // 로그인하지 않은 경우: 이메일 입력 모달 표시
                document.getElementById('emailModal').style.display = 'flex';
                document.body.style.overflow = 'hidden';
            }
        }

        function sendReportByEmail() {
            const emailInput = document.getElementById('recipientEmail');
            const email = emailInput.value.trim();
            const emailError = document.getElementById('emailError');
            const sendingStatus = document.getElementById('sendingStatus');

            // 이메일 유효성 검사
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                emailError.style.display = 'block';
                emailInput.classList.add('is-invalid');
                return;
            }

            emailError.style.display = 'none';
            emailInput.classList.remove('is-invalid');
            sendingStatus.style.display = 'block';

            // 버튼 비활성화
            const sendButton = event.target;
            sendButton.disabled = true;

            // 이메일 전송 API 호출
            fetch('/link10/api/send_report', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    filename: currentFilename,
                    email: email
                })
            })
            .then(response => response.json())
            .then(data => {
                sendingStatus.style.display = 'none';
                sendButton.disabled = false;

                if (data.success) {
                    // 성공 토스트 메시지
                    showToast('success', '전송 완료', '이메일이 성공적으로 전송되었습니다!');
                    closeEmailModal();
                } else {
                    // 실패 토스트 메시지
                    showToast('danger', '전송 실패', data.message || '알 수 없는 오류가 발생했습니다.');
                }
            })
            .catch(error => {
                sendingStatus.style.display = 'none';
                sendButton.disabled = false;
                // 오류 토스트 메시지
                showToast('danger', '오류 발생', '이메일 전송 중 오류가 발생했습니다.');
            });
        }

        window.onclick = function (event) {
            const aiModal = document.getElementById('aiModal');
            const emailModal = document.getElementById('emailModal');

            if (event.target == aiModal) {
                closeAiModal();
            }
            if (event.target == emailModal) {
                closeEmailModal();
            }
        }

        // ESC 키로 모달 닫기
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                const modal = document.getElementById('aiModal');
                if (modal.style.display === 'flex') {
                    closeAiModal();
                }
            }
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>