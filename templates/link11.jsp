<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - 정보보호공시</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <style>
        /* [조윤진] 정보보호공시 디자인 시스템 */
        :root {
            --accent-gradient: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            --glass-border: #e2e8f0;
            --premium-shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --card-radius: 16px;
        }


        /* Glassmorphism 통계 카드 */
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 24px;
            margin-bottom: 50px;
        }

        .stat-card {
            background: white;
            border: 1px solid var(--glass-border);
            border-radius: var(--card-radius);
            padding: 30px;
            text-align: left;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
            display: flex;
            flex-direction: column;
            gap: 10px;
            position: relative;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            color: white;
            margin-bottom: 5px;
        }

        .stat-icon.investment { background: linear-gradient(135deg, #3b82f6 0%, #0ea5e9 100%); }
        .stat-icon.personnel { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); }
        .stat-icon.certification { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); }
        .stat-icon.activity { background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%); }

        .stat-value {
            font-size: 2.22rem;
            font-weight: 850;
            color: #0f172a;
            letter-spacing: -0.02em;
            display: flex;
            align-items: baseline;
            gap: 4px;
        }

        .stat-chart-container {
            width: 80px;
            height: 80px;
            position: absolute;
            right: 20px;
            top: 55%;
            transform: translateY(-50%);
        }

        .stat-label {
            color: #64748b;
            font-size: 0.9rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.02em;
        }


        /* 카테고리 카드 그리드 */
        .category-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 25px;
        }

        .category-card {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: var(--card-radius);
            padding: 24px;
            transition: all 0.3s ease;
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            cursor: pointer;
        }

        .category-card:hover {
            border-color: #3b82f6;
            box-shadow: 0 12px 20px -10px rgba(59, 130, 246, 0.15);
            transform: scale(1.02);
        }

        .category-header {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 20px;
        }

        .category-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            color: white;
            background: #64748b; /* Default */
        }

        .category-title {
            font-size: 1.15rem;
            font-weight: 700;
            color: #1e293b;
        }

        .category-progress {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-top: 15px;
            border-top: 1px solid #f1f5f9;
        }

        .category-stats {
            font-size: 0.85rem;
            color: #64748b;
            font-weight: 500;
        }

        .category-badge {
            padding: 5px 14px;
            border-radius: 8px;
            font-size: 0.8rem;
            font-weight: 800;
            letter-spacing: 0.01em;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            transition: all 0.3s ease;
        }

        .category-badge.complete { background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); color: #166534; border: 1px solid rgba(22, 101, 52, 0.1); }
        .category-badge.in-progress { background: linear-gradient(135deg, #fef9c3 0%, #fef08a 100%); color: #854d0e; border: 1px solid rgba(133, 77, 14, 0.1); }
        .category-badge.not-started { background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%); color: #475569; border: 1px solid rgba(71, 85, 105, 0.1); }

        /* 질문 뷰 및 섹션 */
        .questions-section {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: var(--card-radius);
            padding: 40px;
            box-shadow: var(--premium-shadow);
        }

        .question-item {
            padding: 24px;
            border-radius: 12px;
            margin-bottom: 20px;
            border: 1px solid #f1f5f9;
            transition: all 0.2s ease;
        }

        .question-item.level-1 {
            background: white;
            border-left: 5px solid #3b82f6;
            box-shadow: 0 2px 4px rgba(0,0,0,0.02);
        }

        .question-item.level-2 { background: #f8fafc; margin-left: 20px; }
        .question-item.level-3 { background: white; margin-left: 40px; border-left: 3px dashed #cbd5e1; }

        /* 확정(confirmed) 잠금 상태 */
        #questions-list.disclosure-locked {
            position: relative;
            pointer-events: none;
            opacity: 0.72;
            user-select: none;
        }
        #questions-list.disclosure-locked::after {
            content: '';
            position: absolute;
            inset: 0;
            background: repeating-linear-gradient(
                -45deg,
                transparent,
                transparent 12px,
                rgba(6,95,70,0.04) 12px,
                rgba(6,95,70,0.04) 13px
            );
            border-radius: 8px;
            pointer-events: none;
        }

        /* 그리드 가로 배치 */
        .question-row-container {
            display: flex;
            gap: 16px;
            margin-left: 20px;
            flex-wrap: wrap;
            margin-bottom: 4px;
        }

        .question-row-container .question-grid-item {
            flex: 1;
            min-width: 180px;
        }

        .question-row-container .question-grid-item .number-input,
        .question-row-container .question-grid-item .currency-input {
            width: 100%;
            box-sizing: border-box;
        }

        @media (max-width: 768px) {
            .question-row-container { flex-direction: column; }
        }

        .question-text {
            font-size: 1.1rem;
            font-weight: 600;
            color: #1e293b;
        }

        .question-number {
            background: #3b82f6;
            color: white;
            padding: 3px 10px;
            border-radius: 6px;
            font-weight: 700;
            flex-shrink: 0;
        }

        .question-header {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

        /* 안내문구 툴팁 (question-number 마우스오버) */
        .question-number[data-tooltip] {
            position: relative;
            cursor: help;
        }

        .question-number[data-tooltip]::after {
            content: attr(data-tooltip);
            position: absolute;
            bottom: calc(100% + 8px);
            left: 0;
            background: #1e293b;
            color: rgba(255,255,255,0.92);
            padding: 8px 12px;
            border-radius: 8px;
            font-size: 0.78rem;
            font-weight: 400;
            font-family: 'Pretendard', 'Inter', sans-serif;
            white-space: normal;
            width: max-content;
            max-width: 280px;
            min-width: 160px;
            word-break: keep-all;
            line-height: 1.5;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.15s ease;
            z-index: 200;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }

        .question-number[data-tooltip]:hover::after {
            opacity: 1;
        }

        /* 그리드 아이템 텍스트 크기 축소 */
        .question-grid-item .question-text {
            font-size: 0.9rem;
        }

        /* 그리드 아이템 헤더: 질문번호 아래에 텍스트 배치 */
        .question-grid-item .question-header {
            flex-direction: column;
            align-items: flex-start;
        }

        .question-reset-btn {
            margin-left: auto;
            flex-shrink: 0;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 10px;
            font-size: 0.72rem;
            font-weight: 600;
            color: #94a3b8;
            background: transparent;
            border: 1px solid #e2e8f0;
            border-radius: 20px;
            cursor: pointer;
            transition: color 0.15s, border-color 0.15s, background 0.15s;
            white-space: nowrap;
        }

        .question-reset-btn:hover {
            color: #ef4444;
            border-color: #fca5a5;
            background: #fef2f2;
        }

        /* 버튼 프리미엄 업그레이드 */
        .btn-primary-custom, .btn-secondary-custom {
            padding: 12px 24px;
            border-radius: 10px;
            font-weight: 700;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 0.95rem;
            cursor: pointer;
            border: none;
        }

        .btn-primary-custom {
            background: linear-gradient(13point5deg, #2563eb 0%, #3b82f6 100%);
            color: white;
            box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .btn-primary-custom:hover {
            transform: translateY(-2px) scale(1.02);
            box-shadow: 0 20px 25px -5px rgba(37, 99, 235, 0.4);
            filter: brightness(1.1);
        }

        .btn-secondary-custom {
            background: rgba(255, 255, 255, 0.8);
            backdrop-filter: blur(5px);
            color: #475569;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        }

        .btn-secondary-custom:hover {
            background: white;
            border-color: #3b82f6;
            color: #3b82f6;
            transform: translateY(-1px);
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }

        /* 공시자료 생성 버튼 전용 골드 그래디언트 (윤지현 가이드) */
        .btn-success-premium {
            background: linear-gradient(135deg, #059669 0%, #10b981 100%);
            color: white;
            font-weight: 800;
            padding: 12px 28px;
            border-radius: 12px;
            border: none;
            box-shadow: 0 10px 20px -5px rgba(16, 185, 129, 0.4);
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }

        .btn-success-premium:hover {
            transform: translateY(-3px) scale(1.05);
            box-shadow: 0 20px 30px -10px rgba(16, 185, 129, 0.5);
            filter: brightness(1.15);
        }

        .action-buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 50px;
            margin-bottom: 30px;
        }

        /* 폼 요소 고도화 */
        .number-input, .currency-input, .text-input {
            background: #fdfdfd;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 14px 18px;
            font-size: 1.1rem;
            font-family: 'JetBrains Mono', 'Consolas', monospace;
            transition: all 0.2s ease;
        }

        .text-input {
            font-family: 'Pretendard', 'Inter', sans-serif;
            font-size: 0.95rem;
            line-height: 1.6;
            resize: vertical;
            width: 100%;
            box-sizing: border-box;
        }

        .text-input::placeholder {
            font-family: 'Pretendard', 'Inter', sans-serif;
            font-size: 0.88rem;
            color: #94a3b8;
        }

        .number-input, .currency-input {
            text-align: right;
        }

        .number-input::placeholder, .currency-input::placeholder {
            font-family: 'Pretendard', 'Inter', sans-serif;
            font-size: 0.88rem;
            color: #94a3b8;
            text-align: left;
        }

        .number-input:focus, .currency-input:focus {
            background: white;
            border-color: #3b82f6;
            box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
            outline: none;
        }

        .yes-no-buttons {
            margin-top: 10px;
        }

        .currency-input-wrapper, .number-input, .text-input {
            margin-top: 10px;
        }

        .yes-no-btn {
            border: 1px solid #e2e8f0;
            background: white;
            padding: 6px 18px;
            font-weight: 700;
            border-radius: 8px;
        }

        .yes-no-btn.selected.yes { background: #dcfce7; border-color: #22c55e; color: #166534; }
        .yes-no-btn.selected.no { background: #fee2e2; border-color: #ef4444; color: #991b1b; }

        /* 증빙 업로드 영역 스페셜 스타일 */
        .evidence-section {
            background: #fafafa;
            border: 1px dashed #cbd5e1;
            border-radius: 10px;
            padding: 20px;
            margin-top: 15px;
        }

        .evidence-title {
            font-size: 0.85rem;
            font-weight: 600;
            color: #475569;
            margin-bottom: 8px;
        }

        .evidence-list {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 14px;
        }

        .evidence-item {
            background: #e0f2fe;
            color: #0369a1;
            font-size: 0.8rem;
            font-weight: 500;
            padding: 3px 10px;
            border-radius: 20px;
        }

        .evidence-upload-btn {
            background: #0f172a;
            color: white;
            padding: 10px 18px;
            border-radius: 8px;
            font-weight: 600;
            border: none;
            transition: all 0.2s;
        }

        .evidence-upload-btn:hover { background: #1e293b; transform: scale(1.02); }

        /* 토스트 메시지 프리미엄화 */
        .toast {
            border: none;
            border-radius: 12px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            overflow: hidden;
        }

        .toast-header {
            border-bottom: none;
            padding: 12px 16px;
        }

        .toast-body { padding: 16px; font-weight: 500; }

        /* 모바일 대응 최적화 */
        @media (max-width: 768px) {
            .stat-value { font-size: 1.8rem; }
            .questions-section { padding: 20px; }
        }

        /* [조윤진] 전년도 참고 패널 (Reference View) */
        .reference-panel {
            position: fixed;
            top: 0;
            right: -450px;
            width: 450px;
            height: 100vh;
            background: rgba(255, 255, 255, 0.98);
            backdrop-filter: blur(20px);
            box-shadow: -10px 0 30px rgba(0, 0, 0, 0.1);
            z-index: 1050;
            transition: all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
            display: flex;
            flex-direction: column;
            border-left: 1px solid var(--glass-border);
        }

        .reference-panel.open {
            right: 0;
        }

        .reference-header {
            padding: 25px;
            background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .reference-body {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
        }

        .ref-item {
            background: #f8fafc;
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 16px;
            border: 1px solid #e2e8f0;
        }

        .ref-q-num {
            font-weight: 800;
            color: #3b82f6;
            font-size: 0.85rem;
            margin-bottom: 4px;
            display: block;
        }

        .ref-q-text {
            font-weight: 600;
            color: #475569;
            font-size: 0.95rem;
            margin-bottom: 10px;
            display: block;
        }

        .ref-a-box {
            background: white;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 0.9rem;
            color: #1e293b;
            white-space: pre-wrap;
            word-break: break-all;
        }

        .ref-badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: #fee2e2;
            color: #991b1b;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 700;
            margin-bottom: 8px;
        }

        .reference-toggle-btn {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            color: #64748b;
            padding: 8px 16px;
            border-radius: 50px;
            font-weight: 700;
            font-size: 0.85rem;
            transition: all 0.2s;
        }

        .reference-toggle-btn:hover {
            background: #3b82f6;
            color: white;
            border-color: #3b82f6;
            transform: translateY(-2px);
        }

        .reference-toggle-btn.active {
            background: #3b82f6;
            color: white;
        }
    </style>
</head>

<body>
    <!-- 네비게이션 -->
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <!-- 페이지 헤더 -->
        <div class="mb-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
            <h1><i class="fas fa-shield-alt me-2 text-primary"></i>정보보호공시</h1>
            <!-- [조윤진] 대상 연도 선택기 + 진행률 인라인 배지 -->
            <div class="d-flex align-items-center gap-2 flex-wrap">
                <div class="year-selector-container">
                    <span class="year-label"><i class="fas fa-calendar-check me-2"></i>공시 대상 연도:</span>
                    <select class="year-select" id="disclosure-year-select" onchange="changeDisclosureYear()">
                        <!-- [입력 연도와 공시 연도의 분리] JS에서 동적 생성 -->
                    </select>
                </div>
                <button class="reference-toggle-btn" onclick="toggleReferencePanel()">
                    <i class="fas fa-history me-1"></i> 전년도 참고
                </button>
                <span id="header-progress-badge" class="text-secondary" style="display:inline-flex;align-items:center;gap:6px;background:#f8f9fa;padding:6px 14px 6px 12px;border-radius:50px;border:1px solid #dee2e6;font-size:0.85rem;font-weight:600;">
                    <i class="fas fa-tasks"></i><span id="header-progress-text">0 / 29</span>
                </span>
            </div>
        </div>

        <!-- 로그인 필요 알림 -->
        {% if not is_logged_in %}
        <div class="alert-custom alert-warning text-center">
            <i class="fas fa-exclamation-triangle"></i>
            정보보호공시 기능을 사용하려면 <a href="{{ url_for('login') }}">로그인</a>이 필요합니다.
        </div>
        {% endif %}

        <!-- 대시보드 뷰 (기본) -->
        <div id="dashboard-view">

            <!-- 비율 요약 대시보드 -->
            <div class="dashboard-grid mb-5">
                <div class="stat-card">
                    <div class="stat-icon investment">
                        <i class="fas fa-hand-holding-usd"></i>
                    </div>
                    <div class="stat-label">정보보호 투자 비율</div>
                    <div class="stat-value"><span id="dashboard-inv-ratio">0.00</span><small style="font-size: 1rem; font-weight: 600;">%</small></div>
                    <div class="stat-chart-container">
                        <canvas id="invChart"></canvas>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon personnel">
                        <i class="fas fa-user-shield"></i>
                    </div>
                    <div class="stat-label">정보보호 인력 비율</div>
                    <div class="stat-value"><span id="dashboard-per-ratio">0.00</span><small style="font-size: 1rem; font-weight: 600;">%</small></div>
                    <div class="stat-chart-container">
                        <canvas id="perChart"></canvas>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon certification">
                        <i class="fas fa-medal"></i>
                    </div>
                    <div class="stat-label">보유 인증 건수</div>
                    <div class="stat-value">
                        <span id="dashboard-cert-count">0</span>
                        <small style="font-size: 1rem; font-weight: 600; color: #64748b; margin-left: 2px;">건</small>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon activity">
                        <i class="fas fa-rocket"></i>
                    </div>
                    <div class="stat-label">보안 활동 지수</div>
                    <div class="stat-value">
                        <span id="dashboard-act-score">--</span>
                        <small style="font-size: 1rem; font-weight: 600; color: #64748b; margin-left: 2px;">점</small>
                    </div>
                </div>
            </div>

            <!-- 카테고리 카드 -->
            <h3 class="mb-4"><i class="fas fa-folder-open"></i> 카테고리별 질문</h3>
            <div class="category-grid" id="category-list">
                <!-- JavaScript로 동적 생성 -->
                <div class="loading-spinner">
                    <div class="spinner"></div>
                    <p class="mt-3 text-muted">카테고리 로딩 중...</p>
                </div>
            </div>

            <!-- 확정 상태 배너 (confirmed일 때만 표시) -->
            <div id="confirmed-banner" style="display:none; background:linear-gradient(135deg,#065f46,#047857); color:#fff; border-radius:12px; padding:14px 20px; margin-bottom:16px; display:none; align-items:center; gap:12px;">
                <i class="fas fa-lock fa-lg"></i>
                <div>
                    <strong>공시 확정 완료</strong>
                    <span style="margin-left:8px; opacity:0.85; font-size:0.9rem;">이 공시는 최종 확정되어 수정이 불가합니다.</span>
                </div>
            </div>

            <!-- 액션 버튼 -->
            <div class="action-buttons">
                {% if is_logged_in %}
                <button class="btn-secondary-custom" id="btn-reset" onclick="confirmReset()" style="color: #dc3545;">
                    <i class="fas fa-redo"></i> 새로하기
                </button>
                {% endif %}
                <button class="btn-secondary-custom" onclick="location.href='/link11/evidence'">
                    <i class="fas fa-file-alt"></i> 증빙자료 관리
                </button>
                <!-- 제출하기 (100% 완료 + submitted 미만 상태) -->
                <button id="btn-submit" class="btn-success-premium" onclick="submitDisclosure()" style="display:none;">
                    <i class="fas fa-paper-plane"></i> 공시 제출
                </button>
                <!-- 최종 확정 (submitted 상태) -->
                <button id="btn-confirm" class="btn-success-premium" onclick="confirmDisclosure()" style="display:none; background:linear-gradient(135deg,#065f46,#059669);">
                    <i class="fas fa-check-double"></i> 최종 확정
                </button>
                <!-- 확정 취소 (confirmed 상태, 관리자) -->
                <button id="btn-unconfirm" class="btn-secondary-custom" onclick="unconfirmDisclosure()" style="display:none; color:#b45309;">
                    <i class="fas fa-unlock"></i> 확정 취소
                </button>
                <button class="btn-success-premium" onclick="location.href='/link11/report'">
                    <i class="fas fa-file-export"></i> 공시자료 생성
                </button>
            </div>
        </div>

        <!-- 질문 응답 뷰 (카테고리 선택 시) -->
        <div id="questions-view" style="display: none;">
            <div class="mb-4">
                <button class="btn-secondary-custom" onclick="showDashboard()">
                    <i class="fas fa-arrow-left"></i> 공시 현황으로 돌아가기
                </button>
            </div>

            <div class="questions-section">
                <h3 class="mb-4" id="category-title">질문 목록</h3>
                <div id="questions-list">
                    <!-- JavaScript로 동적 생성 -->
                </div>
            </div>

            <div class="action-buttons">
                <button class="btn-secondary-custom" onclick="showDashboard()">
                    <i class="fas fa-th-large"></i> 공시 현황
                </button>
                <button class="btn-secondary-custom" onclick="saveDraft()">
                    <i class="fas fa-save"></i> 임시 저장
                </button>
                <button class="btn-secondary-custom" onclick="saveAndNext()">
                    <i class="fas fa-arrow-right"></i> 저장 후 다음
                </button>
            </div>
        </div>
    </div>

    <!-- 파일 업로드 모달 -->
    <div class="modal fade" id="uploadModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">증빙자료 업로드</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="upload-form" enctype="multipart/form-data">
                        <input type="hidden" id="upload-question-id" name="question_id">
                        <div class="mb-3">
                            <label class="form-label">증빙 유형</label>
                            <select class="form-select" id="upload-evidence-type" name="evidence_type">
                                <option value="">선택하세요</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">파일 선택</label>
                            <input type="file" class="form-control" id="upload-file" name="file" required>
                            <small class="text-muted">최대 100MB, PDF/Word/Excel/이미지 형식 지원</small>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
                    <button type="button" class="btn btn-primary" onclick="uploadFile()">업로드</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 전년도 참고 사이드 패널 -->
    <div id="reference-panel" class="reference-panel">
        <div class="reference-header">
            <h5 class="mb-0"><i class="fas fa-history me-2"></i>전년도 자료 참고</h5>
            <button type="button" class="btn-close btn-close-white" onclick="toggleReferencePanel()"></button>
        </div>
        <div class="p-3 bg-light border-bottom">
            <div class="d-flex align-items-center gap-2">
                <select class="form-select form-select-sm" id="ref-year-select" onchange="loadReferenceData()">
                    <option value="">연도 선택</option>
                </select>
                <small class="text-muted">내용을 확인하며 직접 입력해 주세요.</small>
            </div>
        </div>
        <div id="ref-status-area" class="px-3 pt-3" style="display:none;"></div>
        <div id="reference-content" class="reference-body">
            <div class="text-center py-5 text-muted">
                <i class="fas fa-calendar-alt fa-3x mb-3 opacity-20"></i>
                <p>연도를 선택하면 전년도 답변 내용이 표시됩니다.</p>
            </div>
        </div>
    </div>

    <!-- 토스트 컨테이너 (Bootstrap) -->
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1100;">
    </div>

    <!-- 스크립트 -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // 질문 ID 상수 (백엔드 QID 클래스와 동기화)
        const QID = {
            // 1. 정보보호 투자 현황 (9개)
            INV_HAS_INVESTMENT: "Q1",    // 정보보호 투자 발생 여부
            INV_IT_AMOUNT: "Q2",         // 정보기술부문 투자액 A
            INV_SEC_GROUP: "Q3",         // 정보보호부문 투자액 B Group
            INV_SEC_DEPRECIATION: "Q4",  // 감가상각비
            INV_SEC_SERVICE: "Q5",       // 서비스비용
            INV_SEC_LABOR: "Q6",         // 인건비
            INV_FUTURE_PLAN: "Q7",       // 향후 투자 계획
            INV_FUTURE_AMOUNT: "Q8",     // 예정 투자액
            INV_MAIN_ITEMS: "Q27",       // 주요 투자 항목

            // 2. 정보보호 인력 현황 (8개)
            PER_HAS_TEAM: "Q9",          // 전담 부서/인력 여부
            PER_TOTAL_EMP: "Q10",        // 총 임직원 수
            PER_IT_EMP: "Q28",           // 정보기술부문 인력 수 C
            PER_INTERNAL: "Q11",         // 내부 전담인력 수 D1
            PER_EXTERNAL: "Q12",         // 외주 전담인력 수 D2
            PER_HAS_CISO: "Q13",         // CISO/CPO 지정 여부
            PER_CISO_DETAIL: "Q14",      // CISO/CPO 상세 현황
            PER_CISO_ACTIVITY: "Q29",    // CISO/CPO 활동내역

            // 3. 정보보호 인증 (2개)
            CERT_HAS_CERT: "Q15",        // 인증 보유 여부
            CERT_DETAIL: "Q16",          // 인증 보유 현황

            // 4. 정보보호 활동 (10개)
            ACT_HAS_ACTIVITY: "Q17",     // 이용자 보호 활동 여부
            ACT_ASSET_MGMT: "Q18",       // IT 자산 관리
            ACT_TRAINING: "Q19",         // 교육/훈련 실적
            ACT_GUIDELINES: "Q20",       // 지침/절차서
            ACT_VULN_ANALYSIS: "Q21",    // 취약점 분석
            ACT_ZERO_TRUST: "Q22",       // 제로트러스트
            ACT_SBOM: "Q23",             // SBOM
            ACT_CTAS: "Q24",             // C-TAS
            ACT_MOCK_DRILL: "Q25",       // 모의훈련
            ACT_INSURANCE: "Q26"         // 배상책임보험
        };

        // [김유신] 실무 사이클(매년 상반기 전년도분 공시)을 반영한 지능형 연도 초기화
        const now = new Date();
        const defaultYear = now.getMonth() < 6 ? now.getFullYear() - 1 : now.getFullYear(); // 6월 전이면 전년도 기본
        
        // 전역 변수
        let currentYear = defaultYear;
        let userId = {{ user_info.user_id if user_info else 0 }};
        let companyName = '{{ user_info.company_name if user_info else "default" }}';
        let questions = [];
        let answers = {};
        let isSaving = false; // 중복 저장 방지 플래그
        let toastCounter = 0; // 토스트 고유 ID 카운터

        // 보안 솔루션 용어 툴팁 매핑
        const securityTerms = {
            '방화벽': 'Firewall - 네트워크 트래픽을 IP/포트 기반으로 차단하는 보안 장비',
            'IDS/IPS': 'Intrusion Detection/Prevention System - 침입 탐지/방지 시스템',
            'SIEM': 'Security Information and Event Management - 보안 정보 및 이벤트 관리',
            'DLP': 'Data Loss Prevention - 데이터 유출 방지',
            'EDR': 'Endpoint Detection and Response - 엔드포인트 탐지 및 대응',
            'WAF': 'Web Application Firewall - 웹 공격(SQL Injection, XSS 등)을 차단하는 특수 방화벽',
            'VPN': 'Virtual Private Network - 가상 사설망',
            'CISSP': 'Certified Information Systems Security Professional - 국제 공인 정보 시스템 보안 전문가',
            'CEH': 'Certified Ethical Hacker - 공인 윤리적 해커',
            'ISO27001': 'International Organization for Standardization 27001 - 국제 정보보안 관리체계 인증',
            'ISO27018': 'ISO 27018 - 클라우드 개인정보보호 인증',
            'SOC2': 'Service Organization Control 2 - 서비스 조직 통제 보고서',
            'CSAP': 'Cloud Security Assurance Program - 클라우드 보안 인증',
            'ISMS': 'Information Security Management System - 정보보안 관리체계'
        };
        let currentCategory = null;
        let allCategories = []; // 서버에서 받아온 전체 카테고리 목록 저장

        // 질문 표시 번호 계산 함수
        function getDisplayQuestionNumber(question) {
            // display_number 컬럼 사용 (없으면 ID로 fallback)
            return question.display_number || question.id;
        }

        // 카테고리 아이콘 매핑 (상단 요약 카드와 1:1 동기화)
        const categoryIcons = {
            '정보보호 투자': { icon: 'fas fa-hand-holding-usd', color: 'linear-gradient(135deg, #3b82f6 0%, #0ea5e9 100%)' },
            '정보보호 인력': { icon: 'fas fa-user-shield', color: 'linear-gradient(135deg, #10b981 0%, #34d399 100%)' },
            '정보보호 인증': { icon: 'fas fa-medal', color: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)' },
            '정보보호 활동': { icon: 'fas fa-rocket', color: 'linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%)' }
        };

        // 페이지 로드 시 초기화
        document.addEventListener('DOMContentLoaded', async function () {
            initYearSelector();      // [조윤진] 연도 선택기 초기화
            initCharts();            // 차트 엔진 초기화
            await loadCategories();  // 카테고리 로드 완료 후
            await loadProgress();    // 진행률 로드
        });

        // [양윤기] 공시 대상 연도 선택기 초기화 (입력 시점 기준 5년치)
        function initYearSelector() {
            const select = document.getElementById('disclosure-year-select');
            if (!select) return;
            
            const currentActualYear = new Date().getFullYear();
            select.innerHTML = '';
            
            // [최윤아] 최근 5개년 공시 프로젝트 관리 지원
            for (let y = currentActualYear; y >= currentActualYear - 4; y--) {
                const option = document.createElement('option');
                option.value = y;
                option.textContent = `${y}년`;
                if (y === currentYear) option.selected = true;
                select.appendChild(option);
            }
        }

        // [김유신] 공시 연도 변경 시 전체 데이터 리프레시
        async function changeDisclosureYear() {
            const select = document.getElementById('disclosure-year-select');
            const newYear = parseInt(select.value);
            
            if (newYear === currentYear) return;
            
            currentYear = newYear;
            showToast(`${currentYear}년 공시로 전환되었습니다.`, 'info');
            
            // 모든 질문/답변 상태 초기화
            answers = {};
            
            // UI 업데이트
            if (currentCategoryId && currentCategory) {
                await showCategory(currentCategoryId, currentCategory);
            } else {
                await loadProgress();
                await loadCategories(); 
            }
        }

        // 카테고리 목록 로드
        async function loadCategories() {
            try {
                const response = await fetch('/link11/api/categories');
                const data = await response.json();

                if (data.success) {
                    allCategories = data.categories; // 전역 변수에 저장
                    renderCategories(data.categories);
                }
            } catch (error) {
                console.error('카테고리 로드 오류:', error);
                document.getElementById('category-list').innerHTML = `
                    <div class="alert-custom alert-error">
                        카테고리를 불러오는 중 오류가 발생했습니다.
                    </div>
                `;
            }
        }

        // 카테고리 렌더링
        function renderCategories(categories) {
            const container = document.getElementById('category-list');
            container.innerHTML = '';

            categories.forEach((cat, index) => {
                const iconInfo = categoryIcons[cat.name] || { icon: 'fas fa-folder', color: '#6b7280' };
                const card = document.createElement('div');
                card.className = 'category-card';
                card.dataset.categoryId = cat.id;  // ID 저장
                card.onclick = () => showCategory(cat.id, cat.name);

                // 카테고리 이름을 안전한 ID로 변환 (공백과 특수문자 제거)
                const safeId = cat.name.replace(/\s+/g, '-');

                card.innerHTML = `
                    <div class="category-header">
                        <div class="category-icon" style="background: ${iconInfo.color}">
                            <i class="${iconInfo.icon}"></i>
                        </div>
                        <h4 class="category-title">${cat.name}</h4>
                    </div>
                    <p class="text-muted mb-0">총 ${cat.total}개 질문 (1단계 ${cat.level1_count}개)</p>
                    <div class="category-progress">
                        <span class="category-stats">진행률: <span id="cat-progress-${safeId}">0%</span></span>
                        <span class="category-badge not-started" id="cat-badge-${safeId}">미시작</span>
                    </div>
                `;

                container.appendChild(card);
            });
        }

        // 진행률 로드
        async function loadProgress() {
            {% if is_logged_in %}
            try {
                console.log('[진행률 로드] 시작...', { userId, currentYear });
                const response = await fetch(`/link11/api/progress/${userId}/${currentYear}`);
                const data = await response.json();
                console.log('[진행률 로드] 응답 데이터:', data);

                if (data.success) {
                    updateProgressUI(data);
                    if (data.ratios) {
                        updateDashboardStats(data.ratios);
                    }
                    updateConfirmUI(data.session, data.progress);
                    console.log('[진행률 로드] UI 업데이트 완료');
                } else {
                    console.error('[진행률 로드] 실패:', data.message);
                }
            } catch (error) {
                console.error('[진행률 로드] 오류:', error);
            }
            {% else %}
            console.warn('[진행률 로드] 로그인 필요');
            {% endif %}
        }

        // 진행률 UI 업데이트
        function updateProgressUI(data) {
            console.log('[진행률 UI 업데이트] 시작', data);
            const progress = data.progress;
            const categories = data.categories;

            // 헤더 진행률 배지 업데이트
            document.getElementById('header-progress-text').textContent =
                `${progress.answered_questions} / ${progress.total_questions}`;

            // 보고서 생성 버튼 활성화 (버튼이 있는 경우에만)
            const reportBtn = document.getElementById('generate-report-btn');
            if (reportBtn && progress.completion_rate === 100) {
                reportBtn.disabled = false;
            }

            // 카테고리별 진행률
            console.log('[진행률 UI 업데이트] 카테고리 데이터:', categories);
            for (const [name, catData] of Object.entries(categories)) {
                // 카테고리 이름을 안전한 ID로 변환 (공백과 특수문자 제거)
                const safeId = name.replace(/\s+/g, '-');
                console.log(`[진행률 UI 업데이트] ${name} -> ${safeId}, rate: ${catData.rate}%`);

                const progressEl = document.getElementById(`cat-progress-${safeId}`);
                const badgeEl = document.getElementById(`cat-badge-${safeId}`);

                if (progressEl) {
                    console.log(`[진행률 UI 업데이트] ✓ progressEl 발견: cat-progress-${safeId}`);
                    progressEl.textContent = `${catData.rate}%`;
                } else {
                    console.warn(`[진행률 UI 업데이트] ✗ progressEl 없음: cat-progress-${safeId}`);
                }

                if (badgeEl) {
                    if (catData.rate === 100) {
                        badgeEl.className = 'category-badge complete';
                        badgeEl.textContent = '완료';
                    } else if (catData.rate > 0) {
                        badgeEl.className = 'category-badge in-progress';
                        badgeEl.textContent = '진행중';
                    } else {
                        badgeEl.className = 'category-badge not-started';
                        badgeEl.textContent = '미시작';
                    }
                }
            }
        }

        // 확정 프로세스 UI 업데이트
        function updateConfirmUI(session, progress) {
            const status = session ? session.status : 'draft';
            const isComplete = progress && progress.completion_rate === 100;

            const btnSubmit    = document.getElementById('btn-submit');
            const btnConfirm   = document.getElementById('btn-confirm');
            const btnUnconfirm = document.getElementById('btn-unconfirm');
            const btnReset     = document.getElementById('btn-reset');
            const banner       = document.getElementById('confirmed-banner');
            const qList        = document.getElementById('questions-list');

            // 모두 숨긴 뒤 상태별 표시
            [btnSubmit, btnConfirm, btnUnconfirm].forEach(b => { if (b) b.style.display = 'none'; });
            if (banner) banner.style.display = 'none';

            if (status === 'confirmed') {
                if (banner) banner.style.display = 'flex';
                if (btnUnconfirm) btnUnconfirm.style.display = 'inline-flex';
                if (btnReset) btnReset.style.display = 'none';
                // 입력 잠금
                if (qList) {
                    qList.classList.add('disclosure-locked');
                    qList.querySelectorAll('input, textarea, select, button').forEach(el => {
                        el.disabled = true;
                    });
                }
            } else {
                // 잠금 해제
                if (qList) {
                    qList.classList.remove('disclosure-locked');
                    qList.querySelectorAll('input, textarea, select, button').forEach(el => {
                        el.disabled = false;
                    });
                }
                if (status === 'submitted') {
                    if (btnConfirm) btnConfirm.style.display = 'inline-flex';
                } else {
                    // draft / in_progress / completed
                    if (isComplete && btnSubmit) btnSubmit.style.display = 'inline-flex';
                }
            }
        }

        // 공시 제출
        async function submitDisclosure() {
            if (!confirm('공시를 제출하시겠습니까?\n제출 후에는 담당자 확정이 필요합니다.')) return;
            try {
                const res = await fetch(`/link11/api/submit/${userId}/${currentYear}`, { method: 'POST' });
                const data = await res.json();
                if (data.success) {
                    showToast('공시가 제출되었습니다.', 'success');
                    await loadProgress();
                } else {
                    showToast(data.message || '제출 실패', 'error');
                }
            } catch (e) {
                showToast('제출 중 오류가 발생했습니다.', 'error');
            }
        }

        // 최종 확정
        async function confirmDisclosure() {
            if (!confirm('공시를 최종 확정하시겠습니까?\n확정 후에는 수정이 불가합니다.')) return;
            try {
                const res = await fetch(`/link11/api/confirm/${userId}/${currentYear}`, { method: 'POST' });
                const data = await res.json();
                if (data.success) {
                    showToast('공시가 최종 확정되었습니다.', 'success');
                    await loadProgress();
                } else {
                    showToast(data.message || '확정 실패', 'error');
                }
            } catch (e) {
                showToast('확정 중 오류가 발생했습니다.', 'error');
            }
        }

        // 확정 취소 (관리자)
        async function unconfirmDisclosure() {
            if (!confirm('확정을 취소하시겠습니까?')) return;
            try {
                const res = await fetch(`/link11/api/unconfirm/${userId}/${currentYear}`, { method: 'POST' });
                const data = await res.json();
                if (data.success) {
                    showToast('확정이 취소되었습니다.', 'success');
                    await loadProgress();
                } else {
                    showToast(data.message || '취소 실패', 'error');
                }
            } catch (e) {
                showToast('취소 중 오류가 발생했습니다.', 'error');
            }
        }

        // 차트 객체 전역 관리
        let invChartObj = null;
        let perChartObj = null;

        function initCharts() {
            const chartConfig = (color) => ({
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [0, 100],
                        backgroundColor: [color, 'rgba(226, 232, 240, 0.4)'],
                        borderWidth: 0,
                        cutout: '82%'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { 
                        legend: { display: false }, 
                        tooltip: { enabled: false } 
                    },
                    animation: { duration: 2500, easing: 'easeOutQuart' },
                    // 비중 차트임을 강조하기 위해 각도 조정 없음 (0도부터 시작)
                }
            });

            const invCanvas = document.getElementById('invChart');
            const perCanvas = document.getElementById('perChart');
            
            if (invCanvas) invChartObj = new Chart(invCanvas, chartConfig('#3b82f6'));
            if (perCanvas) perChartObj = new Chart(perCanvas, chartConfig('#10b981'));
        }

        // 대시보드 모든 지표 업데이트 (Share Matrix & Stats 동기화)
        function updateDashboardStats(ratios) {
            const invRatio = document.getElementById('dashboard-inv-ratio');
            const perRatio = document.getElementById('dashboard-per-ratio');
            const certCount = document.getElementById('dashboard-cert-count');
            const actScore = document.getElementById('dashboard-act-score');
            
            const invVal = ratios.investment_ratio || 0;
            const perVal = ratios.personnel_ratio || 0;
            const certVal = ratios.certification_count || 0;
            const scoreVal = ratios.activity_score || 0;

            if (invRatio) invRatio.textContent = invVal.toFixed(2);
            if (perRatio) perRatio.textContent = perVal.toFixed(2);
            if (certCount) certCount.textContent = certVal;
            if (actScore) {
                actScore.textContent = scoreVal;
                // 점수에 따른 다이내믹 컬러링 (윤지현 가이드)
                if (scoreVal >= 70) actScore.style.color = '#10b981';
                else if (scoreVal >= 30) actScore.style.color = '#f59e0b';
                else actScore.style.color = '#94a3b8';
            }

            // 비중 차트 유기적 업데이트
            if (invChartObj) {
                invChartObj.data.datasets[0].data = [invVal, Math.max(0, 100 - invVal)];
                invChartObj.update();
            }
            if (perChartObj) {
                perChartObj.data.datasets[0].data = [perVal, Math.max(0, 100 - perVal)];
                perChartObj.update();
            }
        }

        // 카테고리 질문 표시
        let currentCategoryId = null;
        const GRID_QUESTION_GROUPS = {
            'Q9': ['Q10', 'Q28', 'Q11', 'Q12'], // 인력 현황 (총임직원, IT인력, 내부, 외주)
            'Q3': ['Q4', 'Q5', 'Q6']           // 투자액 상세 (감가, 서비스, 인건비)
        };

        function isGridQuestion(qid) {
            return Object.values(GRID_QUESTION_GROUPS).flat().includes(qid);
        }

        async function showCategory(categoryId, categoryName) {
            currentCategory = categoryName;
            currentCategoryId = categoryId;
            document.getElementById('dashboard-view').style.display = 'none';
            document.getElementById('questions-view').style.display = 'block';
            document.getElementById('category-title').textContent = categoryName;

            try {
                // 질문 로드 (카테고리 ID로 요청)
                const qResponse = await fetch(`/link11/api/questions?category=${categoryId}`);
                const qData = await qResponse.json();

                if (qData.success) {
                    questions = qData.questions;

                    // 기존 답변 로드
                    {% if is_logged_in %}
                    const aResponse = await fetch(`/link11/api/answers/${userId}/${currentYear}`);
                    const aData = await aResponse.json();

                    if (aData.success) {
                        answers = {};
                        aData.answers.forEach(a => {
                            answers[a.question_id] = a.value;
                        });
                    }
                    {% endif %}

                    renderQuestions(questions);

                    // 금액 필드 초기 포맷팅 및 비율 계산
                    setTimeout(() => {
                        const itAmountInput = document.getElementById(`input-${QID.INV_IT_AMOUNT}`);
                        const secGroupInput = document.getElementById(`input-${QID.INV_SEC_GROUP}`);
                        if (itAmountInput && itAmountInput.value) formatCurrencyOnBlur(itAmountInput);
                        if (secGroupInput && secGroupInput.value) formatCurrencyOnBlur(secGroupInput);
                        calculateInvestmentRatio();
                    }, 100);
                }
            } catch (error) {
                console.error('질문 로드 오류:', error);
            }
        }

        // 질문 렌더링
        function renderQuestions(questions) {
            const container = document.getElementById('questions-list');
            container.innerHTML = '';

            // 1단계 질문부터 재귀적으로 렌더링
            const level1Questions = questions.filter(q => q.level === 1);
            level1Questions.forEach(q => {
                appendQuestionRecursive(container, q);
            });
        }

        function appendQuestionRecursive(container, q) {
            const isGrid = isGridQuestion(q.id);
            const questionEl = createQuestionElement(q);

            if (isGrid) {
                questionEl.classList.add('question-grid-item');
            }

            container.appendChild(questionEl);

            if (q.dependent_question_ids && isQuestionTriggered(q, answers[q.id])) {
                const groupChildren = GRID_QUESTION_GROUPS[q.id];

                if (groupChildren) {
                    // 가로 배치를 위한 컨테이너 생성
                    const rowContainer = document.createElement('div');
                    rowContainer.className = 'question-row-container';
                    container.appendChild(rowContainer);

                    q.dependent_question_ids.forEach(depId => {
                        const depQ = questions.find(dq => dq.id === depId);
                        if (depQ) {
                            if (groupChildren.includes(depId)) {
                                appendQuestionRecursive(rowContainer, depQ);
                            } else {
                                appendQuestionRecursive(container, depQ);
                            }
                        }
                    });
                } else {
                    q.dependent_question_ids.forEach(depId => {
                        const depQ = questions.find(dq => dq.id === depId);
                        if (depQ) {
                            appendQuestionRecursive(container, depQ);
                        }
                    });
                }
            }

            // yes_no 타입이고 증빙이 있으면 text 타입 종속 질문 앞에 삽입 (없으면 마지막에 추가)
            if (q.type === 'yes_no' && q.evidence_list && q.evidence_list.length > 0) {
                const isVisible = answers[q.id] === 'YES';
                const evidenceTitle = q.evidence_title || '필요한 증빙 자료';
                const evidenceEl = document.createElement('div');
                evidenceEl.className = 'evidence-section';
                evidenceEl.id = `evidence-${q.id}`;
                evidenceEl.style.display = isVisible ? 'block' : 'none';
                evidenceEl.style.marginLeft = `${q.level * 20}px`;
                evidenceEl.innerHTML = `
                    <div class="evidence-title">
                        <i class="fas fa-paperclip"></i> ${evidenceTitle}
                    </div>
                    <div class="evidence-list">
                        ${q.evidence_list.map(e => `<span class="evidence-item">${e}</span>`).join('')}
                    </div>
                    <button class="evidence-upload-btn" onclick="openUploadModal('${q.id}', ${JSON.stringify(q.evidence_list).replace(/"/g, '&quot;')})">
                        <i class="fas fa-upload"></i> 파일 업로드
                    </button>
                `;

                // text 타입 종속 질문이 있으면 그 앞에 삽입, 없으면 마지막에 추가
                let insertBeforeEl = null;
                if (q.dependent_question_ids) {
                    for (const depId of q.dependent_question_ids) {
                        const depQ = questions.find(dq => dq.id === depId);
                        if (depQ && (depQ.type === 'text' || depQ.type === 'textarea')) {
                            insertBeforeEl = document.getElementById(`question-${depId}`);
                            break;
                        }
                    }
                }

                if (insertBeforeEl) {
                    container.insertBefore(evidenceEl, insertBeforeEl);
                } else {
                    container.appendChild(evidenceEl);
                }
            }
        }

        // 질문 의존성 트리거 여부 확인
        function isQuestionTriggered(question, answerValue) {
            // Group 유형은 부모가 보이면 항상 하위 항목을 트리거함
            if (question.type === 'group') return true;

            if (answerValue === undefined || answerValue === null || answerValue === '') return false;

            if (question.type === 'yes_no') {
                return answerValue === 'YES' || answerValue === 'yes' || answerValue === 'Yes';
            }
            return false;
        }

        // 질문 요소 생성
        function createQuestionElement(q) {
            const div = document.createElement('div');
            div.className = `question-item level-${q.level}`;
            div.id = `question-${q.id}`;

            let answerHtml = '';
            const currentValue = answers[q.id] || '';

            switch (q.type) {
                case 'yes_no':
                    answerHtml = `
                        <div class="yes-no-buttons">
                            <button class="yes-no-btn yes ${currentValue === 'YES' ? 'selected' : ''}"
                                    onclick="selectYesNo('${q.id}', 'YES', this)">
                                <i class="fas fa-check"></i> 예
                            </button>
                            <button class="yes-no-btn no ${currentValue === 'NO' ? 'selected' : ''}"
                                    onclick="selectYesNo('${q.id}', 'NO', this)">
                                <i class="fas fa-times"></i> 아니오
                            </button>
                        </div>
                    `;
                    break;

                case 'group':
                    if (q.id === QID.INV_SEC_GROUP) {
                        const sum = parseFloat(currentValue) || 0;
                        answerHtml = `
                            <div class="group-header" style="margin-bottom: 12px; border-radius: 12px; background: rgba(59, 130, 246, 0.05); border-left: 5px solid #3b82f6; padding: 15px;">
                                <i class="fas fa-layer-group" style="margin-right: 8px;"></i> 정보보호 투자액(B) - 다음 3개 항목의 합계
                            </div>
                            <div id="investment-total-display" class="total-display" style="margin-bottom: 10px; padding: 20px; background: white; border-radius: 16px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                <span style="font-weight: 700; color: #64748b; font-size: 0.95rem; text-transform: uppercase; letter-spacing: 0.05em;">정보보호 투자액 합계(B)</span>
                                <span id="input-${QID.INV_SEC_GROUP}-display" style="font-size: 1.5rem; font-weight: 850; color: #1e293b; font-family: 'JetBrains Mono', monospace;">${formatCurrency(sum)}<span style="font-size: 1rem; margin-left: 4px; font-weight: 600;">원</span></span>
                                <input type="hidden" id="input-${QID.INV_SEC_GROUP}" value="${sum}" data-raw-value="${sum}">
                            </div>
                            <div id="investment-ratio-display" class="ratio-display" style="padding: 16px; background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%); border-radius: 12px; border-left: 5px solid #0ea5e9; display: flex; align-items: center; gap: 12px;">
                                <div style="width: 36px; height: 36px; background: #0ea5e9; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px;">
                                    <i class="fas fa-calculator"></i>
                                </div>
                                <div>
                                    <div style="color: #0369a1; font-weight: 600; font-size: 0.85rem;">IT 예산 대비 정보보호 투자 비율</div>
                                    <div id="ratio-value" style="color: #0ea5e9; font-weight: 800; font-size: 1.25rem;">--%</div>
                                </div>
                            </div>
                        `;
                    } else {
                        answerHtml = `
                            <div class="group-header">
                                <i class="fas fa-layer-group"></i> 아래 상세 항목을 입력해 주세요.
                            </div>
                        `;
                    }
                    break;

                case 'table':
                    const tableOptions = q.options ? (typeof q.options === 'string' ? JSON.parse(q.options) : q.options) : [];
                    let tableData = [];
                    try {
                        tableData = currentValue ? (typeof currentValue === 'string' ? JSON.parse(currentValue) : currentValue) : [{}];
                        if (!Array.isArray(tableData)) tableData = [{}];
                    } catch (e) { tableData = [{}]; }

                    const DATE_COL_KEYWORDS = ['기간', '일자', '날짜'];
                    const isDateCol = (colName) => DATE_COL_KEYWORDS.some(k => colName.includes(k));
                    const toDateInputVal = (v) => {
                        if (!v) return '';
                        // YYYY.MM.DD 또는 YYYY/MM/DD → YYYY-MM-DD
                        return v.replace(/\./g, '-').replace(/\//g, '-');
                    };

                    let tableRowsHtml = tableData.map((row, idx) => `
                        <tr>
                            ${tableOptions.map(opt => {
                                const isDate = isDateCol(opt);
                                const val = isDate ? toDateInputVal(row[opt] || '') : (row[opt] || '');
                                return `
                                <td>
                                    <input type="${isDate ? 'date' : 'text'}" class="table-input"
                                           data-row-idx="${idx}" data-col-name="${opt}"
                                           value="${val}"
                                           oninput="handleTableInput('${q.id}', this)"
                                           style="width: 100%; border: none; padding: 5px; outline: none;">
                                </td>`;
                            }).join('')}
                            <td style="width: 40px; text-align: center;">
                                <button class="btn btn-sm btn-outline-danger" onclick="deleteTableRow('${q.id}', ${idx})">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </td>
                        </tr>
                    `).join('');

                    answerHtml = `
                        <div class="table-container" style="overflow-x: auto; background: white; border: 1px solid #e2e8f0; border-radius: 8px;">
                            <table class="table table-bordered mb-0" style="min-width: 600px;">
                                <thead class="table-light">
                                    <tr>
                                        ${tableOptions.map(opt => `<th>${opt}</th>`).join('')}
                                        <th style="width: 50px;">삭제</th>
                                    </tr>
                                </thead>
                                <tbody id="table-body-${q.id}">
                                    ${tableRowsHtml}
                                </tbody>
                            </table>
                            <div class="p-2 bg-light text-end">
                                <button class="btn btn-sm btn-primary" onclick="addTableRow('${q.id}')">
                                    <i class="fas fa-plus"></i> 행 추가
                                </button>
                            </div>
                        </div>
                    `;
                    break;

                case 'text':
                case 'textarea':
                    answerHtml = `
                        <textarea class="text-input" rows="3"
                                  placeholder="${q.help_text || '내용을 입력하세요...'}"
                                  onchange="updateAnswer('${q.id}', this.value)">${currentValue}</textarea>
                    `;
                    break;

                case 'number':
                    // 0도 유효한 값이므로 null/undefined/빈문자열만 체크
                    const hasNumValue = currentValue !== null && currentValue !== undefined && currentValue !== '';
                    if (q.text.includes('(원)')) {
                        // 금액 관련 필드 (천 단위 콤마 + 원 단위 표시)
                        const formattedVal = hasNumValue ? formatCurrency(currentValue) : '';
                        answerHtml = `
                            <div class="currency-input-wrapper" style="position: relative;">
                                <input type="text" class="currency-input" id="input-${q.id}"
                                       placeholder="금액을 입력하세요"
                                       value="${formattedVal}"
                                       data-raw-value="${hasNumValue ? currentValue : ''}"
                                       oninput="handleCurrencyInput(this, '${q.id}')"
                                       onblur="formatCurrencyOnBlur(this)"
                                       style="padding-right: 40px;">
                                <span style="position: absolute; right: 15px; top: 50%; transform: translateY(-50%); color: #64748b; font-weight: 600;">원</span>
                            </div>
                        `;
                    } else {
                        // 일반 숫자 (인원 수, 횟수 등)
                        answerHtml = `
                            <input type="text" class="number-input" id="input-${q.id}"
                                   placeholder="숫자를 입력하세요"
                                   value="${hasNumValue ? formatNumber(currentValue) : ''}"
                                   data-raw-value="${hasNumValue ? currentValue : ''}"
                                   oninput="handleNumberInput(this, '${q.id}')"
                                   onblur="formatNumberOnBlur(this, '${q.id}')">
                        `;
                    }
                    break;

                case 'rank_composition':
                    let rankOptions = [];
                    try {
                        rankOptions = q.options ? JSON.parse(q.options) : [];
                    } catch (e) {
                        rankOptions = ["임원급", "팀장급", "실무자"];
                    }

                    let currentComp = {};
                    try {
                        if (typeof currentValue === 'string' && currentValue.startsWith('{')) {
                            currentComp = JSON.parse(currentValue);
                        } else if (typeof currentValue === 'object' && currentValue !== null) {
                            currentComp = currentValue;
                        }
                    } catch (e) {
                        console.error('JSON parse error for composition:', e);
                        currentComp = {};
                    }

                    let fieldsHtml = rankOptions.map(opt => `
                        <div class="composition-field" style="display: flex; align-items: center; margin-bottom: 8px; gap: 10px;">
                            <span style="flex: 0 0 100px; font-weight: 500; color: #475569;">${opt}</span>
                            <div style="flex: 1; display: flex; align-items: center; gap: 8px;">
                                <input type="number" class="number-input rank-input-${q.id}"
                                       data-rank-name="${opt}"
                                       value="${(currentComp[opt] !== undefined && currentComp[opt] !== null) ? currentComp[opt] : ''}"
                                       oninput="handleCompositionInput('${q.id}')"
                                       placeholder="0"
                                       min="0"
                                       style="padding: 10px; border: 1px solid #cbd5e1; border-radius: 6px; width: 120px; text-align: right; background: white; font-weight: 600;">
                                <span class="text-muted">명</span>
                            </div>
                        </div>
                    `).join('');

                    const totalComp = Object.values(currentComp).reduce((a, b) => (Number(a) || 0) + (Number(b) || 0), 0);

                    answerHtml = `
                        <div class="composition-container" style="background: #f1f5f9; padding: 20px; border-radius: 12px; border: 1px solid #e2e8f0;">
                            <div style="margin-bottom: 15px; font-size: 0.9rem; color: #64748b; display: flex; align-items: center; gap: 6px;">
                                <i class="fas fa-info-circle"></i> 각 항목에 숫자를 입력하면 합계가 자동 계산됩니다.
                            </div>
                            ${fieldsHtml}
                            <div class="composition-total" style="margin-top: 20px; padding-top: 15px; border-top: 2px dashed #cbd5e1; display: flex; align-items: center; justify-content: flex-end; gap: 15px;">
                                <span style="font-weight: 700; color: #1e293b; font-size: 1.1rem;">총 인원 합계:</span>
                                <div style="display: flex; align-items: baseline; gap: 4px;">
                                    <span id="total-${q.id}" style="font-size: 1.8rem; font-weight: 800; color: #3b82f6;">${totalComp}</span>
                                    <span style="font-weight: 700; color: #1e293b; font-size: 1.1rem;">명</span>
                                </div>
                            </div>
                        </div>
                    `;
                    break;

                case 'date':
                    answerHtml = `
                        <input type="month" class="date-input"
                               value="${currentValue}"
                               onchange="updateAnswer('${q.id}', this.value)">
                    `;
                    break;

                case 'select':
                    const options = q.options || [];
                    answerHtml = `
                        <div class="select-group">
                            ${options.map(opt => `
                                <div class="radio-item ${currentValue === opt ? 'selected' : ''}"
                                     onclick="selectOption('${q.id}', '${opt}', this)">
                                    <i class="fas ${currentValue === opt ? 'fa-check-circle' : 'fa-circle'}"></i>
                                    ${opt}
                                </div>
                            `).join('')}
                        </div>
                    `;
                    break;

                case 'checkbox':
                    const checkOptions = q.options || [];
                    const selectedValues = Array.isArray(currentValue) ? currentValue : [];
                    answerHtml = `
                        <div class="checkbox-group">
                            <div class="checkbox-none-hint" style="font-size:0.8rem; color:#94a3b8; margin-bottom:6px;">선택하지 않으면 미수행으로 처리됩니다</div>
                            ${checkOptions.map(opt => {
                        const tooltip = securityTerms[opt] ? `title="${securityTerms[opt]}"` : '';
                        return `
                                <div class="checkbox-item ${selectedValues.includes(opt) ? 'selected' : ''}"
                                     data-value="${opt}"
                                     onclick="toggleCheckbox('${q.id}', '${opt}', this)"
                                     ${tooltip}>
                                    <i class="fas ${selectedValues.includes(opt) ? 'fa-check-square' : 'fa-square'}"></i>
                                    ${opt}
                                </div>
                            `}).join('')}
                        </div>
                    `;
                    break;
            }

            // 증빙 자료 섹션 (yes_no 타입은 appendQuestionRecursive에서 하위 질문 뒤에 별도 렌더링)
            let evidenceHtml = '';
            if (q.evidence_list && q.evidence_list.length > 0 && q.type !== 'yes_no') {
                const evidenceTitle = q.evidence_title || '필요한 증빙 자료';
                evidenceHtml = `
                    <div class="evidence-section" id="evidence-${q.id}">
                        <div class="evidence-title">
                            <i class="fas fa-paperclip"></i> ${evidenceTitle}
                        </div>
                        <div class="evidence-list">
                            ${q.evidence_list.map(e => `<span class="evidence-item">${e}</span>`).join('')}
                        </div>
                        <button class="evidence-upload-btn" onclick="openUploadModal('${q.id}', ${JSON.stringify(q.evidence_list).replace(/"/g, '&quot;')})">
                            <i class="fas fa-upload"></i> 파일 업로드
                        </button>
                    </div>
                `;
            }

            const displayNumber = getDisplayQuestionNumber(q);

            const isGrid = isGridQuestion(q.id);
            let formattedText = q.text;
            if (isGrid && formattedText.includes(' (')) {
                // 공백 + 괄호 형태(상세 설명)만 줄바꿈하고 스타일에 적용
                // (C), (D1) 처럼 공백 없이 붙은 기호는 제목으로 취급하여 한 줄 유지
                formattedText = formattedText.replace(' (', '<br><small class="text-muted" style="font-weight: normal; font-size: 0.8rem; margin-top: 4px; display: inline-block;">(');
            }

            let formattedHelpText = q.help_text || '';
            if (isGrid && formattedHelpText.includes('(')) {
                // 부모 괄호와 내용 삭제 (중복 방지)
                formattedHelpText = formattedHelpText.replace(/\s*\(.*?\)/g, '').trim();
            }

            div.innerHTML = `
                <div class="question-header">
                    <span class="question-number" ${formattedHelpText ? `data-tooltip="${formattedHelpText.replace(/"/g, '&quot;')}"` : ''}>${displayNumber}</span>
                    <span class="question-text">${formattedText}</span>
                    ${(q.type !== 'number' && !isGrid) ? `
                    <button class="question-reset-btn" onclick="resetQuestion('${q.id}'); event.stopPropagation();" title="이 질문 초기화">
                        <i class="fas fa-undo"></i> 초기화
                    </button>
                    ` : ''}
                </div>
                <div class="answer-section">
                    ${answerHtml}
                </div>
                ${evidenceHtml}
            `;

            return div;
        }

        // YES/NO 선택
        // YES/NO 선택
        async function selectYesNo(questionId, value, btn) {
            const question = questions.find(q => q.id === questionId);

            if (value === 'NO' && question && question.dependent_question_ids) {
                // 재귀적으로 모든 하위 답변이 존재하는지 확인
                const hasAnswers = checkAnyDependentAnswers(question);

                if (hasAnswers) {
                    if (!confirm('상위 질문을 "아니오"로 변경하면 이미 작성된 모든 하위 데이터가 삭제됩니다. 계속하시겠습니까?')) {
                        return;
                    }
                    // 로컬 및 DB에서 재귀적 삭제 (API 호출 포함)
                    recursiveClearAnswers(question);
                }
            }

            const buttons = btn.parentElement.querySelectorAll('.yes-no-btn');
            buttons.forEach(b => b.classList.remove('selected'));
            btn.classList.add('selected');

            updateAnswer(questionId, value);

            if (question && question.dependent_question_ids) {
                if (value === 'YES') {
                    showDependentQuestions(question);
                } else {
                    hideDependentQuestions(question);
                }
            }

            // yes_no 질문의 증빙 섹션 표시 토글
            const evidenceSection = document.getElementById(`evidence-${questionId}`);
            if (evidenceSection) {
                evidenceSection.style.display = (value === 'YES') ? 'block' : 'none';
            }
        }

        // 재귀적으로 하위 답변 존재 여부 확인
        function checkAnyDependentAnswers(parentQ) {
            if (!parentQ.dependent_question_ids) return false;
            for (const depId of parentQ.dependent_question_ids) {
                if (answers[depId] !== undefined && answers[depId] !== null && answers[depId] !== '') return true;
                const depQ = questions.find(q => q.id === depId);
                if (depQ && checkAnyDependentAnswers(depQ)) return true;
            }
            return false;
        }

        // 재귀적으로 하위 답변 데이터 삭제
        function recursiveClearAnswers(parentQ) {
            if (!parentQ.dependent_question_ids) return;
            parentQ.dependent_question_ids.forEach(depId => {
                delete answers[depId];
                // DB에서도 삭제되도록 (백엔드에서 이미 처리하지만 동기화를 위해)
                const depQ = questions.find(q => q.id === depId);
                if (depQ) recursiveClearAnswers(depQ);
            });
        }

        // 종속 질문 표시
        function showDependentQuestions(parentQuestion) {
            console.log(`[showDependentQuestions] 부모 질문: ${parentQuestion.id}, 종속 질문:`, parentQuestion.dependent_question_ids);
            
            const parentEl = document.getElementById(`question-${parentQuestion.id}`);
            if (!parentEl) {
                console.error(`[showDependentQuestions] 부모 요소를 찾을 수 없음: question-${parentQuestion.id}`);
                return;
            }

            // 종속 질문을 역순으로 처리하여 부모 바로 아래에 올바른 순서로 삽입
            const reversedIds = [...parentQuestion.dependent_question_ids].reverse();
            reversedIds.forEach(depId => {
                const existingEl = document.getElementById(`question-${depId}`);
                if (!existingEl) {
                    const depQ = questions.find(dq => dq.id === depId);
                    if (depQ) {
                        console.log(`[showDependentQuestions] 종속 질문 생성 중: ${depId}`);
                        const depEl = createQuestionElement(depQ);
                        
                        if (isGridQuestion(depId)) {
                            depEl.classList.add('question-grid-item');
                            // 가로 배치 컨테이너가 없으면 생성 (동축 표시 대응)
                            let rowContainer = parentEl.nextElementSibling;
                            if (!rowContainer || !rowContainer.classList.contains('question-row-container')) {
                                rowContainer = document.createElement('div');
                                rowContainer.className = 'question-row-container';
                                parentEl.after(rowContainer);
                            }
                            rowContainer.prepend(depEl);
                        } else {
                            parentEl.after(depEl);
                        }

                        // DOM 삽입 확인
                        setTimeout(() => {
                            const inserted = document.getElementById(`question-${depId}`);
                            if (inserted) {
                                console.log(`[showDependentQuestions] ✓ 종속 질문 DOM 삽입 성공: ${depId}`);
                            } else {
                                console.error(`[showDependentQuestions] ✗ 종속 질문 DOM 삽입 실패: ${depId}`);
                            }
                        }, 100);

                        // 하위의 하위 질문도 트리거 여부 확인하여 표시 (재귀)
                        if (depQ.dependent_question_ids && isQuestionTriggered(depQ, answers[depId])) {
                            showDependentQuestions(depQ);
                        }
                    } else {
                        console.error(`[showDependentQuestions] 종속 질문을 찾을 수 없음: ${depId}`);
                    }
                } else {
                    console.log(`[showDependentQuestions] 종속 질문이 이미 존재함: ${depId}`);
                }
            });
        }

        // 종속 질문 숨기기
        function hideDependentQuestions(parentQuestion) {
            parentQuestion.dependent_question_ids.forEach(depId => {
                const depEl = document.getElementById(`question-${depId}`);
                if (depEl) {
                    // 재귀적으로 하위의 하위 질문들도 삭제
                    const depQ = questions.find(q => q.id === depId);
                    if (depQ && depQ.dependent_question_ids) {
                        hideDependentQuestions(depQ);
                    }
                    depEl.remove();
                    delete answers[depId];
                }
            });
        }

        // 옵션 선택 (라디오)
        function selectOption(questionId, value, el) {
            const items = el.parentElement.querySelectorAll('.radio-item');
            items.forEach(item => {
                item.classList.remove('selected');
                item.querySelector('i').className = 'fas fa-circle';
            });
            el.classList.add('selected');
            el.querySelector('i').className = 'fas fa-check-circle';

            // 옵션 선택은 즉시 저장
            updateAnswer(questionId, value);
        }

        // 체크박스 토글
        function toggleCheckbox(questionId, value, el) {
            console.log(`[toggleCheckbox] 질문: ${questionId}, 값: ${value}, 이전 상태:`, el.classList.contains('selected'));
            
            el.classList.toggle('selected');
            const icon = el.querySelector('i');
            icon.className = el.classList.contains('selected') ? 'fas fa-check-square' : 'fas fa-square';

            console.log(`[toggleCheckbox] 새 상태:`, el.classList.contains('selected'));

            // 현재 선택된 값들 수집
            const container = el.parentElement;
            const selectedValues = [];
            container.querySelectorAll('.checkbox-item.selected').forEach(item => {
                const val = item.getAttribute('data-value') || item.textContent.trim();
                selectedValues.push(val);
            });
            
            console.log(`[toggleCheckbox] 선택된 값들:`, selectedValues);
            updateAnswer(questionId, selectedValues);
        }

        // 답변 업데이트 (메모리에만 저장, DB 저장은 명시적 버튼 클릭 시에만)
        function updateAnswer(questionId, value) {
            answers[questionId] = value;
            // 자동 저장 제거 - '임시 저장' 또는 '저장 후 다음' 버튼 클릭 시에만 저장됨
        }

        // 개별 답변 DB 저장 및 진행률 갱신
        async function saveOneAnswer(questionId, value) {
            try {
                const response = await fetch('/link11/api/answers', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        question_id: questionId,
                        value: value,
                        year: currentYear
                    })
                });

                const data = await response.json();
                if (data.success) {
                    loadProgress();
                } else if (data.message && data.message.includes('초과')) {
                    showToast(data.message, 'error');
                    // 입력값 원래대로 또는 강조? 
                }
            } catch (error) {
                console.error('실시간 저장 오류:', error);
            }
        }

        // 금액 포맷팅 (천 단위 쉼표)
        function formatCurrency(value) {
            if (!value && value !== 0) return '';
            const num = String(value).replace(/[^\d]/g, '');
            if (!num) return '';
            return parseInt(num, 10).toLocaleString('ko-KR');
        }

        // 금액 입력 처리
        function handleCurrencyInput(input, questionId) {
            // 숫자만 추출
            const rawValue = input.value.replace(/[^\d]/g, '');
            input.dataset.rawValue = rawValue;

            // 답변 업데이트
            updateAnswer(questionId, rawValue);

            // 비율 계산
            calculateInvestmentRatio();
        }

        // blur 시 포맷팅 적용
        function formatCurrencyOnBlur(input) {
            const rawValue = input.dataset.rawValue || input.value.replace(/[^\d]/g, '');
            if (rawValue) {
                input.value = formatCurrency(rawValue);
            }
        }

        // 구성 입력 처리 (Q2-4 등)
        function handleCompositionInput(questionId) {
            const inputs = document.querySelectorAll(`.rank-input-${questionId}`);
            let composition = {};
            let total = 0;

            inputs.forEach(input => {
                const val = parseInt(input.value) || 0;
                const name = input.dataset.rankName;
                composition[name] = val;
                total += val;
            });

            // 합계 표시 업데이트
            const totalEl = document.getElementById(`total-${questionId}`);
            if (totalEl) totalEl.textContent = total;

            // JSON 문자열로 저장
            updateAnswer(questionId, JSON.stringify(composition));
        }

        // 숫자 입력 처리
        function formatNumber(value) {
            if (!value && value !== 0) return '';
            const num = String(value).replace(/[^\d.]/g, '');
            if (!num) return '';

            // 소수점 처리
            const parts = num.split('.');
            parts[0] = parseInt(parts[0], 10).toLocaleString('ko-KR');

            return parts.length > 1 ? parts.join('.') : parts[0];
        }

        // 숫자 입력 처리
        function handleNumberInput(input, questionId) {
            // 숫자와 소수점만 추출 (음수 방지)
            let rawValue = input.value.replace(/[^\d.]/g, '');

            // 음수 방지: 값이 0보다 작으면 0으로 설정
            if (rawValue && parseFloat(rawValue) < 0) {
                rawValue = '0';
                showToast('음수는 입력할 수 없습니다.', 'warning');
            }

            // 소수점이 여러 개 있으면 첫 번째만 유지
            const parts = rawValue.split('.');
            if (parts.length > 2) {
                rawValue = parts[0] + '.' + parts.slice(1).join('');
            }

            input.dataset.rawValue = rawValue;

            // 답변 업데이트 (raw value 사용)
            updateAnswer(questionId, rawValue);

            // 정보보호 투자액 하위 항목인 경우 상위 합계 계산
            const securitySubItems = [QID.INV_SEC_DEPRECIATION, QID.INV_SEC_SERVICE, QID.INV_SEC_LABOR];
            if (securitySubItems.includes(questionId)) {
                calculateSecurityInvestmentSum();
            }
        }

        // blur 시 숫자 포맷팅 및 검증 적용
        let personnelValidationTimer = null;
        function formatNumberOnBlur(input, questionId) {
            const rawValue = input.dataset.rawValue || input.value.replace(/[^\d.]/g, '');
            if (rawValue) {
                input.value = formatNumber(rawValue);
            }

            // 인력 관련 질문인 경우 focus-out 시점에 검증 (debounce 적용)
            const personnelRelatedItems = [QID.PER_TOTAL_EMP, QID.PER_IT_EMP, QID.PER_INTERNAL, QID.PER_EXTERNAL];
            if (questionId && personnelRelatedItems.includes(questionId)) {
                clearTimeout(personnelValidationTimer);
                personnelValidationTimer = setTimeout(() => {
                    calculatePersonnelValidation();
                }, 100);
            }
        }

        // 통화 입력 처리 (콤마 추가)
        function handleCurrencyInput(input, questionId) {
            let rawValue = input.value.replace(/[^\d]/g, '');

            // 음수 방지: 값이 0보다 작으면 0으로 설정
            if (rawValue && parseInt(rawValue) < 0) {
                rawValue = '0';
                showToast('음수는 입력할 수 없습니다.', 'warning');
            }

            input.dataset.rawValue = rawValue;

            // 답변 업데이트
            updateAnswer(questionId, rawValue);

            // 정보보호 투자액 하위 항목인 경우 상위 합계 계산
            const securitySubItems = [QID.INV_SEC_DEPRECIATION, QID.INV_SEC_SERVICE, QID.INV_SEC_LABOR];
            if (securitySubItems.includes(questionId)) {
                calculateSecurityInvestmentSum();
            }

            // 투자 비율 계산
            const investmentRelatedItems = [QID.INV_IT_AMOUNT, QID.INV_SEC_GROUP, ...securitySubItems];
            if (investmentRelatedItems.includes(questionId)) {
                calculateInvestmentRatio();
            }
        }

        function formatCurrencyOnBlur(input) {
            if (input.dataset.rawValue) {
                input.value = formatCurrency(input.dataset.rawValue);
            }
        }

        // 정보보호 투자액 합계 자동 계산 (Group = 감가상각비 + 서비스비용 + 인건비)
        let lastInvestmentToastTime = 0;  // 투자액 검증 토스트 쿨다운
        function calculateSecurityInvestmentSum() {
            const v1 = parseFloat(document.getElementById(`input-${QID.INV_SEC_DEPRECIATION}`)?.dataset.rawValue || 0) || 0;
            const v2 = parseFloat(document.getElementById(`input-${QID.INV_SEC_SERVICE}`)?.dataset.rawValue || 0) || 0;
            const v3 = parseFloat(document.getElementById(`input-${QID.INV_SEC_LABOR}`)?.dataset.rawValue || 0) || 0;

            const sum = v1 + v2 + v3;

            // 정보기술부문 투자액(A) 가져오기
            const totalItInput = document.getElementById(`input-${QID.INV_IT_AMOUNT}`);
            const totalIt = parseFloat(totalItInput?.dataset.rawValue || 0) || 0;

            // 검증: 정보보호 투자액(B)이 정보기술 투자액(A)보다 클 수 없음
            if (sum > totalIt && totalIt > 0) {
                console.error(`[투자액 검증 실패] 정보보호 투자액(${sum.toLocaleString()})이 정보기술 투자액(${totalIt.toLocaleString()})을 초과했습니다.`);

                // 입력 필드 강조 표시
                [QID.INV_SEC_DEPRECIATION, QID.INV_SEC_SERVICE, QID.INV_SEC_LABOR].forEach(qid => {
                    const input = document.getElementById(`input-${qid}`);
                    if (input) {
                        input.style.borderColor = '#ef4444';
                        input.style.backgroundColor = '#fef2f2';
                    }
                });

                if (totalItInput) {
                    totalItInput.style.borderColor = '#ef4444';
                    totalItInput.style.backgroundColor = '#fef2f2';
                }

                // 에러 토스트 표시 (중복 방지 ID 지정)
                const now = Date.now();
                if ((now - lastInvestmentToastTime) > 3000) {
                    lastInvestmentToastTime = now;
                    showToast(`정보보호 투자액(${sum.toLocaleString()}원)이 정보기술 투자액(${totalIt.toLocaleString()}원)을 초과했습니다.`, 'error', 'inv-err');
                }

                return; // 저장하지 않음
            } else {
                // 정상인 경우 강조 표시 제거
                [QID.INV_SEC_DEPRECIATION, QID.INV_SEC_SERVICE, QID.INV_SEC_LABOR].forEach(qid => {
                    const input = document.getElementById(`input-${qid}`);
                    if (input) {
                        input.style.borderColor = '';
                        input.style.backgroundColor = '';
                    }
                });
                
                if (totalItInput) {
                    totalItInput.style.borderColor = '';
                    totalItInput.style.backgroundColor = '';
                }
            }

            // 로컬 상태 업데이트
            answers[QID.INV_SEC_GROUP] = sum;

            // 화면에 입력칸 또는 디스플레이가 있으면 업데이트
            const secGroupInput = document.getElementById(`input-${QID.INV_SEC_GROUP}`);
            const secGroupDisplay = document.getElementById(`input-${QID.INV_SEC_GROUP}-display`);
            
            if (secGroupInput) {
                secGroupInput.value = sum;
                secGroupInput.dataset.rawValue = sum;
            }
            if (secGroupDisplay) {
                secGroupDisplay.innerText = formatCurrency(sum) + '원';
            }

            // 비율 다시 계산
            calculateInvestmentRatio();
        }

        // 정보보호 투자 비율 자동 계산
        function calculateInvestmentRatio() {
            const totalItInput = document.getElementById(`input-${QID.INV_IT_AMOUNT}`);
            const ratioDisplay = document.getElementById('ratio-value');

            if (!totalItInput || !ratioDisplay) return;

            const totalIt = parseFloat((totalItInput.dataset.rawValue || totalItInput.value || '0').toString().replace(/[^\d.]/g, '')) || 0;

            // 정보보호 투자액 Group 입력 필드를 찾거나, 없으면 로컬 데이터 또는 하위 항목 합계 사용
            const secGroupInput = document.getElementById(`input-${QID.INV_SEC_GROUP}`);
            let security = 0;
            if (secGroupInput) {
                security = parseFloat((secGroupInput.dataset.rawValue || secGroupInput.value || '0').toString().replace(/[^\d.]/g, '')) || 0;
            } else {
                // 하위 항목 실시간 합산
                const v1 = parseFloat(document.getElementById(`input-${QID.INV_SEC_DEPRECIATION}`)?.dataset.rawValue || 0) || 0;
                const v2 = parseFloat(document.getElementById(`input-${QID.INV_SEC_SERVICE}`)?.dataset.rawValue || 0) || 0;
                const v3 = parseFloat(document.getElementById(`input-${QID.INV_SEC_LABOR}`)?.dataset.rawValue || 0) || 0;
                security = v1 + v2 + v3;
                if (security === 0 && answers[QID.INV_SEC_GROUP]) security = parseFloat(answers[QID.INV_SEC_GROUP]) || 0;
            }

            if (totalIt > 0) {
                const ratio = (security / totalIt) * 100;
                ratioDisplay.textContent = ratio.toFixed(2) + '%';

                // 유효성 체크 색상 변경 (B > A 인 경우 경고)
                if (security > totalIt) {
                    ratioDisplay.style.color = '#ef4444';
                    totalItInput.style.borderColor = '#ef4444';
                } else {
                    ratioDisplay.style.color = '#2563eb';
                    totalItInput.style.borderColor = '';
                }
            } else {
                ratioDisplay.textContent = '0.00%';
                ratioDisplay.style.color = '#94a3b8';
            }
        }

        // 정보보호 인력 검증 (총 임직원 >= IT 인력(C) >= 정보보호 인력(D1+D2))
        let lastPersonnelToastTime = 0;  // 마지막 토스트 표시 시간
        function calculatePersonnelValidation() {
            const totalEmpInput = document.getElementById(`input-${QID.PER_TOTAL_EMP}`);
            const itEmpInput = document.getElementById(`input-${QID.PER_IT_EMP}`);
            const internalInput = document.getElementById(`input-${QID.PER_INTERNAL}`);
            const externalInput = document.getElementById(`input-${QID.PER_EXTERNAL}`);

            const totalEmp = parseFloat(totalEmpInput?.dataset.rawValue || totalEmpInput?.value || '0') || 0;
            const itEmp = parseFloat(itEmpInput?.dataset.rawValue || itEmpInput?.value || '0') || 0;
            const internal = parseFloat(internalInput?.dataset.rawValue || internalInput?.value || '0') || 0;
            const external = parseFloat(externalInput?.dataset.rawValue || externalInput?.value || '0') || 0;

            const securityPersonnel = internal + external;
            const now = Date.now();
            const canShowToast = (now - lastPersonnelToastTime) > 3000;  // 3초 쿨다운

            // 1차 검증: 정보기술부문 인력(C)이 총 임직원 수보다 클 수 없음
            if (itEmp > totalEmp && totalEmp > 0) {
                if (canShowToast) {
                    lastPersonnelToastTime = now;
                    showToast(`정보기술부문 인력(${itEmp}명)은 총 임직원 수(${totalEmp}명)를 초과할 수 없습니다.`, 'error', 'per-err');
                }
                if (itEmpInput) itEmpInput.style.borderColor = '#ef4444';
                return;
            }

            // 2차 검증: 정보보호 전담인력(D1+D2)이 정보기술부문 인력(C)을 초과할 수 없음
            if (securityPersonnel > itEmp && itEmp > 0) {
                if (canShowToast) {
                    lastPersonnelToastTime = now;
                    showToast(`내·외부 전담인력 합계(D1+D2: ${securityPersonnel}명)가 정보기술부문 인력 수(C: ${itEmp}명)를 초과할 수 없습니다.`, 'error', 'per-err');
                }
                if (internalInput) internalInput.style.borderColor = '#ef4444';
                if (externalInput) externalInput.style.borderColor = '#ef4444';
                return;
            }

            // 정상인 경우 스타일 초기화
            [totalEmpInput, itEmpInput, internalInput, externalInput].forEach(el => {
                if (el) {
                    el.style.borderColor = '';
                    el.style.backgroundColor = '';
                }
            });
        }

        // 테이블 입력 처리
        function handleTableInput(questionId, input) {
            const idx = parseInt(input.dataset.rowIdx);
            const col = input.dataset.colName;

            if (!answers[questionId] || !Array.isArray(answers[questionId])) {
                answers[questionId] = [{}];
            }

            if (!answers[questionId][idx]) answers[questionId][idx] = {};
            answers[questionId][idx][col] = input.value;

            updateAnswer(questionId, answers[questionId]);
        }

        function addTableRow(questionId) {
            if (!answers[questionId] || !Array.isArray(answers[questionId])) {
                answers[questionId] = [];
            }
            answers[questionId].push({});
            // UI 갱신을 위해 해당 질문만 다시 렌더링하거나 전체 렌더링
            const q = questions.find(item => item.id === questionId);
            if (q) {
                const oldEl = document.getElementById(`question-${questionId}`);
                if (oldEl) {
                    const newEl = createQuestionElement(q);
                    oldEl.replaceWith(newEl);
                }
            }
        }

        function deleteTableRow(questionId, idx) {
            if (answers[questionId] && Array.isArray(answers[questionId])) {
                answers[questionId].splice(idx, 1);
                if (answers[questionId].length === 0) answers[questionId] = [{}];
                updateAnswer(questionId, answers[questionId]);

                const q = questions.find(item => item.id === questionId);
                if (q) {
                    const oldEl = document.getElementById(`question-${questionId}`);
                    if (oldEl) {
                        const newEl = createQuestionElement(q);
                        oldEl.replaceWith(newEl);
                    }
                }
            }
        }

        // 토스트 메시지 표시 (ID가 지정되면 유효성/상세 상태 업데이트 지원)
        function showToast(message, type = 'info', fixedId = null) {
            const container = document.querySelector('.toast-container');
            if (!container) return;

            const trimmedMsg = message.trim();
            const existingToastEl = fixedId ? document.getElementById(fixedId) : null;

            if (existingToastEl) {
                // 1. 기존 토스트가 이미 있으면 내용과 스타일만 업데이트 (깜빡임 방지 및 상태 전환)
                const body = existingToastEl.querySelector('.toast-body');
                const header = existingToastEl.querySelector('.toast-header');
                
                if (body) body.textContent = trimmedMsg;
                if (header) {
                    header.className = 'toast-header'; // 클래스 초기화
                    if (type === 'success') header.classList.add('bg-success', 'text-white');
                    else if (type === 'error') header.classList.add('bg-danger', 'text-white');
                    else if (type === 'warning') header.classList.add('bg-warning');
                    else header.classList.add('bg-info', 'text-white');
                }
                
                // 다시 표시 (진행 중인 토스트 시간 연장)
                bootstrap.Toast.getOrCreateInstance(existingToastEl).show();
                return;
            }

            // 2. ID가 없는 경우 본문 내용으로 중복 체크
            if (!fixedId) {
                const existingToasts = container.querySelectorAll('.toast-body');
                for (const t of existingToasts) {
                    if (t.textContent.trim() === trimmedMsg) return;
                }
            }

            // 3. 새 토스트 생성
            const toastId = fixedId || ('toast-' + (++toastCounter));
            const toastHtml = `
                <div id="${toastId}" class="toast" role="alert" aria-live="assertive" aria-atomic="true">
                    <div class="toast-header">
                        <i class="fas fa-info-circle me-2"></i>
                        <strong class="me-auto">알림</strong>
                        <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
                    </div>
                    <div class="toast-body">${trimmedMsg}</div>
                </div>
            `;
            
            container.insertAdjacentHTML('beforeend', toastHtml);
            const toastEl = document.getElementById(toastId);
            const toastHeader = toastEl.querySelector('.toast-header');

            if (type === 'success') toastHeader.classList.add('bg-success', 'text-white');
            else if (type === 'error') toastHeader.classList.add('bg-danger', 'text-white');
            else if (type === 'warning') toastHeader.classList.add('bg-warning');
            else toastHeader.classList.add('bg-info', 'text-white');

            const toast = new bootstrap.Toast(toastEl, { autohide: true, delay: 3000 });
            toast.show();
            toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
        }

        // 답변 저장
        async function saveAnswers() {
            {% if not is_logged_in %}
            showToast('로그인이 필요합니다.', 'warning');
            return { success: false, message: '로그인이 필요합니다.' };
            {% endif %}

            try {
                let errors = [];
                for (const [questionId, value] of Object.entries(answers)) {
                    if (value !== undefined && value !== '' && value !== null) {
                        const response = await fetch('/link11/api/answers', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                question_id: questionId,
                                value: value,
                                year: currentYear
                            })
                        });
                        const data = await response.json();
                        if (!data.success) {
                            errors.push(data.message || '저장 실패');
                        }
                    }
                }
                if (errors.length > 0) {
                    return { success: false, message: errors[0] };  // 첫 번째 오류 반환
                }
                return { success: true };
            } catch (error) {
                console.error('저장 오류:', error);
                return { success: false, message: '저장 중 오류가 발생했습니다.' };
            }
        }

        // 저장 전 전체 유효성 검사
        function validateBeforeSave() {
            // 1. 투자액 검증 (B <= A)
            // 현재 화면에 있는 입력 필드 값 기준 (Answers 객체보다 입력 필드가 최신일 수 있으므로)
            const itAmountInput = document.getElementById(`input-${QID.INV_IT_AMOUNT}`);
            const itAmount = parseFloat(itAmountInput?.dataset.rawValue || itAmountInput?.value?.replace(/,/g, '') || 0) || 0;
            
            const v1 = parseFloat(document.getElementById(`input-${QID.INV_SEC_DEPRECIATION}`)?.dataset.rawValue || 0) || 0;
            const v2 = parseFloat(document.getElementById(`input-${QID.INV_SEC_SERVICE}`)?.dataset.rawValue || 0) || 0;
            const v3 = parseFloat(document.getElementById(`input-${QID.INV_SEC_LABOR}`)?.dataset.rawValue || 0) || 0;
            const securityAmount = v1 + v2 + v3;

            if (itAmount > 0 && securityAmount > itAmount) {
                showToast(`정보보호 투자액(${securityAmount.toLocaleString()}원)이 정보기술 투자액(${itAmount.toLocaleString()}원)을 초과했습니다.`, 'error', 'inv-err');
                return false;
            }

            // 2. 인력 검증 (C <= Total, D <= C)
            const totalEmpInput = document.getElementById(`input-${QID.PER_TOTAL_EMP}`);
            const itEmpInput = document.getElementById(`input-${QID.PER_IT_EMP}`);
            const internalInput = document.getElementById(`input-${QID.PER_INTERNAL}`);
            const externalInput = document.getElementById(`input-${QID.PER_EXTERNAL}`);

            const totalEmp = parseFloat(totalEmpInput?.dataset.rawValue || totalEmpInput?.value?.replace(/,/g, '') || 0) || 0;
            const itEmp = parseFloat(itEmpInput?.dataset.rawValue || itEmpInput?.value?.replace(/,/g, '') || 0) || 0;
            const internal = parseFloat(internalInput?.dataset.rawValue || internalInput?.value?.replace(/,/g, '') || 0) || 0;
            const external = parseFloat(externalInput?.dataset.rawValue || externalInput?.value?.replace(/,/g, '') || 0) || 0;
            const securityPersonnel = internal + external;

            if (totalEmp > 0 && itEmp > totalEmp) {
                showToast(`정보기술부문 인력(${itEmp}명)은 총 임직원 수(${totalEmp}명)를 초과할 수 없습니다.`, 'error', 'per-err');
                return false;
            }
            if (itEmp > 0 && securityPersonnel > itEmp) {
                showToast(`정보보호 인력(${securityPersonnel}명)은 정보기술부문 인력(${itEmp}명)을 초과할 수 없습니다.`, 'error', 'per-err');
                return false;
            }

            return true;
        }

        // 임시 저장
        async function saveDraft() {
            if (isSaving) return;
            isSaving = true;

            try {
                // 실시간 검증 타이머 취소
                clearTimeout(personnelValidationTimer);
                
                if (!validateBeforeSave()) {
                    isSaving = false;
                    return;
                }

                showToast('저장 중입니다...', 'info', 'save-status');
                const result = await saveAnswers();
                if (result.success) {
                    showToast('임시 저장되었습니다.', 'success', 'save-status');
                    loadProgress();
                } else {
                    showToast(result.message || '저장 중 오류가 발생했습니다.', 'error', 'save-status');
                }
            } catch (error) {
                console.error('SaveDraft API error:', error);
                showToast('저장 중 알 수 없는 오류가 발생했습니다.', 'error', 'save-status');
            } finally {
                isSaving = false;
            }
        }

        // 특정 질문 초기화
        async function resetQuestion(questionId) {
            if (!confirm('이 질문의 답변을 초기화하시겠습니까?')) {
                return;
            }

            {% if not is_logged_in %}
            showToast('로그인이 필요합니다.', 'warning');
            return;
            {% endif %}

            try {
                // 답변 삭제 API 호출
                const response = await fetch(`/link11/api/answers/${questionId}`, {
                    method: 'DELETE',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        year: currentYear
                    })
                });

                const data = await response.json();

                if (data.success) {
                    // 로컬 answers 객체에서 제거
                    delete answers[questionId];

                    // 화면 새로고침하여 초기 상태로 되돌림
                    const question = questions.find(q => q.id === questionId);
                    if (question) {
                        // 현재 카테고리 다시 로드
                        if (currentCategoryId && currentCategory) {
                            await showCategory(currentCategoryId, currentCategory);
                        }
                    }

                    showToast('답변이 초기화되었습니다.', 'success');
                    loadProgress();
                } else {
                    showToast('초기화 중 오류가 발생했습니다.', 'error');
                }
            } catch (error) {
                console.error('질문 초기화 오류:', error);
                showToast('초기화 중 오류가 발생했습니다.', 'error');
            }
        }

        // 저장 후 다음 카테고리를 이동
        async function saveAndNext() {
            if (isSaving) return;
            isSaving = true;

            try {
                // 실시간 검증 타이머 취소
                clearTimeout(personnelValidationTimer);

                if (!validateBeforeSave()) {
                    isSaving = false;
                    return;
                }

                showToast('저장 중입니다...', 'info', 'save-status');
                const result = await saveAnswers();
                if (result.success) {
                    showToast('저장되었습니다.', 'success', 'save-status');
                    loadProgress();
                    goToNextCategory();
                } else {
                    showToast(result.message || '저장 중 오류가 발생했습니다.', 'error', 'save-status');
                }
            } catch (error) {
                console.error('SaveAndNext API error:', error);
                showToast('저장 중 알 수 없는 오류가 발생했습니다.', 'error', 'save-status');
            } finally {
                isSaving = false;
            }
        }

        // 다음 카테고리로 이동
        function goToNextCategory() {
            if (!currentCategoryId || allCategories.length === 0) {
                showDashboard();
                return;
            }

            const currentIndex = allCategories.findIndex(c => c.id === currentCategoryId);

            if (currentIndex >= 0 && currentIndex < allCategories.length - 1) {
                // 다음 카테고리로 이동
                const nextCategory = allCategories[currentIndex + 1];
                showToast(`'${nextCategory.name}' 카테고리로 이동합니다.`, 'info');
                showCategory(nextCategory.id, nextCategory.name);
            } else {
                // 마지막 카테고리이면 대시보드로
                showToast('모든 카테고리를 완료했습니다!', 'success');
                showDashboard();
            }
        }

        // 대시보드 표시
        function showDashboard() {
            document.getElementById('dashboard-view').style.display = 'block';
            document.getElementById('questions-view').style.display = 'none';
            currentCategory = null;
            currentCategoryId = null;
            loadProgress();
        }

        // 업로드 모달 열기
        function openUploadModal(questionId, evidenceList) {
            document.getElementById('upload-question-id').value = questionId;

            const select = document.getElementById('upload-evidence-type');
            select.innerHTML = '<option value="">선택하세요</option>';
            evidenceList.forEach(e => {
                const option = document.createElement('option');
                option.value = e;
                option.textContent = e;
                select.appendChild(option);
            });

            const modal = new bootstrap.Modal(document.getElementById('uploadModal'));
            modal.show();
        }

        // 파일 업로드
        async function uploadFile() {
            const form = document.getElementById('upload-form');
            const formData = new FormData(form);
            formData.append('year', currentYear);

            try {
                const response = await fetch('/link11/api/evidence', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (data.success) {
                    showToast('파일이 업로드되었습니다.', 'success');
                    bootstrap.Modal.getInstance(document.getElementById('uploadModal')).hide();
                    form.reset();
                } else {
                    showToast('업로드 실패: ' + data.message, 'error');
                }
            } catch (error) {
                console.error('업로드 오류:', error);
                showToast('업로드 중 오류가 발생했습니다.', 'error');
            }
        }

        // 보고서 생성
        async function generateReport() {
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
                    // 보고서 데이터를 새 창에 표시하거나 다운로드
                    console.log('Report generated:', data.report);
                    showToast('보고서가 생성되었습니다.', 'success');
                } else {
                    showToast('보고서 생성 실패: ' + data.message, 'error');
                }
            } catch (error) {
                console.error('보고서 생성 오류:', error);
                showToast('보고서 생성 중 오류가 발생했습니다.', 'error');
            }
        }

        // 새로하기 확인
        function confirmReset() {
            if (confirm(`${currentYear}년 데이터를 모두 삭제하고 새로 시작하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.`)) {
                resetDisclosure();
            }
        }

        // 데이터 초기화
        async function resetDisclosure() {
            try {
                const response = await fetch(`/link11/api/reset/${userId}/${currentYear}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                });

                const data = await response.json();
                if (data.success) {
                    showToast(data.message, 'success');
                    // 페이지 새로고침
                    setTimeout(() => location.reload(), 1000);
                } else {
                    showToast('초기화 실패: ' + data.message, 'error');
                }
            } catch (error) {
                console.error('초기화 오류:', error);
                showToast('초기화 중 오류가 발생했습니다.', 'error');
            }
        }

        // [김유신] 전년도 참고 사이드 패널 토글
        async function toggleReferencePanel() {
            const panel = document.getElementById('reference-panel');
            const btn = document.querySelector('.reference-toggle-btn');
            
            panel.classList.toggle('open');
            btn.classList.toggle('active');

            if (panel.classList.contains('open')) {
                await updateReferenceYearList();
                loadReferenceData(); // 패널을 열 때 드롭다운 상태와 내용 동기화 (연도 미선택 시 안내 메시지 표시)
            }
        }

        // 참고용 가용 연도 목록 업데이트
        async function updateReferenceYearList() {
            const select = document.getElementById('ref-year-select');
            const currentVal = select.value;

            try {
                const response = await fetch(`/link11/api/available-years/${userId}`);
                const data = await response.json();

                if (data.success) {
                    select.innerHTML = '<option value="">연도 선택</option>';
                    const statusLabel = { confirmed: '확정', submitted: '제출됨', completed: '작성완료', in_progress: '작성중', draft: '초안' };
                    data.years.forEach(y => {
                        if (parseInt(y.year) === currentYear) return; // 현재 연도는 제외
                        const option = document.createElement('option');
                        option.value = y.year;
                        const label = statusLabel[y.status] || y.status;
                        option.textContent = `${y.year}년 [${label}]`;
                        if (y.year == currentVal) option.selected = true;
                        select.appendChild(option);
                    });
                }
            } catch (error) {
                console.error('참고 연도 로드 실패:', error);
            }
        }

        // 전년도 참고 데이터 로드 및 렌더링
        async function loadReferenceData() {
            const year = document.getElementById('ref-year-select').value;
            const content = document.getElementById('reference-content');
            const statusArea = document.getElementById('ref-status-area');

            if (!year) {
                statusArea.style.display = 'none';
                content.innerHTML = `
                    <div class="text-center py-5 text-muted">
                        <i class="fas fa-calendar-alt fa-3x mb-3 opacity-20"></i>
                        <p>연도를 선택하면 전년도 답변 내용이 표시됩니다.</p>
                    </div>
                `;
                return;
            }

            content.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div><p class="mt-2 text-muted">자료 로딩 중...</p></div>';

            try {
                const response = await fetch(`/link11/api/answers/${userId}/${year}`);
                const data = await response.json();

                // 세션 상태 박스 렌더링
                if (data.success && statusArea) {
                    const st = data.status || 'draft';
                    const isDone = ['confirmed', 'submitted', 'completed'].includes(st);
                    const stLabel = { confirmed: '확정', submitted: '제출됨', completed: '작성완료', in_progress: '작성중', draft: '초안' }[st] || st;
                    if (isDone) {
                        statusArea.innerHTML = `
                            <div class="alert alert-guide-info mb-3" style="border-left: 4px solid #10b981 !important;">
                                <i class="fas fa-check-circle text-success"></i>
                                <strong>${year}년 [${stLabel}]</strong> — 검토가 완료된 자료입니다. 안심하고 참고하세요.
                            </div>`;
                    } else {
                        statusArea.innerHTML = `
                            <div class="alert alert-warning mb-3" style="font-size:0.85rem;">
                                <i class="fas fa-exclamation-triangle me-1"></i>
                                <strong>${year}년 [${stLabel}]</strong> — 아직 작성 중인 초안입니다. 참고용으로만 활용하세요.
                            </div>`;
                    }
                    statusArea.style.display = 'block';
                }

                if (data.success && data.answers.length > 0) {
                    let html = '';
                    data.answers.forEach(a => {
                        // 미입력 항목 스킵
                        const v = a.value;
                        if (v === null || v === undefined || v === '' || v === 'N/A') return;
                        if (Array.isArray(v) && v.length === 0) return;

                        const valueDisplay = formatReferenceValue(v, a.question_type);
                        const isQuantitative = ['number', 'rank_composition'].includes(a.question_type);
                        html += `
                            <div class="ref-item">
                                ${isQuantitative ? '<span class="ref-badge"><i class="fas fa-exclamation-circle"></i> 정량 데이터 (재계산 필요)</span>' : ''}
                                <span class="ref-q-num">${a.question_id}</span>
                                <span class="ref-q-text">${a.question_text}</span>
                                <div class="ref-a-box">${valueDisplay}</div>
                            </div>
                        `;
                    });
                    content.innerHTML = html || '<div class="text-center py-5 text-muted">입력된 답변이 없습니다.</div>';
                } else {
                    content.innerHTML = '<div class="text-center py-5 text-muted">해당 연도의 데이터가 없습니다.</div>';
                }
            } catch (error) {
                console.error('참고 데이터 로드 실패:', error);
                content.innerHTML = '<div class="text-center py-5 text-danger">데이터를 불러오는 중 오류가 발생했습니다.</div>';
            }
        }

        // 참고용 데이터 포맷팅
        function formatReferenceValue(value, type) {
            if (value === null || value === undefined || value === '') return '<span class="text-muted">(미입력)</span>';
            
            // JSON 문자열인 경우 파싱 시도
            let parsedValue = value;
            if (typeof value === 'string' && (value.startsWith('[') || value.startsWith('{'))) {
                try {
                    parsedValue = JSON.parse(value);
                } catch (e) {
                    console.warn('JSON 파싱 실패:', value);
                }
            }

            if (type === 'yes_no') {
                return parsedValue === 'YES' ? '<span class="text-success font-weight-bold">예 (YES)</span>' : '<span class="text-danger font-weight-bold">아니오 (NO)</span>';
            }
            
            // 테이블 형식 (Array) 처리
            if (Array.isArray(parsedValue)) {
                if (parsedValue.length === 0) return '<span class="text-muted">(데이터 없음)</span>';
                
                let tableHtml = '<div style="font-size: 0.85rem; margin-top: 5px; border: 1px solid #e2e8f0; border-radius: 6px; overflow: hidden;">';
                const keys = Object.keys(parsedValue[0]);
                
                // 헤더
                tableHtml += '<div style="display: flex; background: #f8fafc; border-bottom: 1px solid #e2e8f0; font-weight: 700; color: #64748b;">';
                keys.forEach(k => tableHtml += `<div style="flex: 1; padding: 6px 10px; border-right: 1px solid #e2e8f0;">${k}</div>`);
                tableHtml += '</div>';

                // 행
                parsedValue.forEach(row => {
                    tableHtml += '<div style="display: flex; border-bottom: 1px solid #f1f5f9; background: white;">';
                    keys.forEach(k => {
                        const val = row[k] || '-';
                        tableHtml += `<div style="flex: 1; padding: 6px 10px; border-right: 1px solid #e2e8f0; word-break: break-all;">${val}</div>`;
                    });
                    tableHtml += '</div>';
                });
                tableHtml += '</div>';
                return tableHtml;
            }

            // 구성 형식 (Object) 처리
            if (typeof parsedValue === 'object') {
                let listHtml = '<ul style="margin: 5px 0 0 0; padding-left: 18px; font-size: 0.85rem; color: #475569;">';
                for (const [k, v] of Object.entries(parsedValue)) {
                    listHtml += `<li style="margin-bottom: 2px;"><span style="font-weight: 600;">${k}:</span> ${v}</li>`;
                }
                listHtml += '</ul>';
                return listHtml;
            }
            
            if (type === 'number') {
                const num = parseFloat(parsedValue);
                return isNaN(num) ? String(parsedValue) : num.toLocaleString();
            }

            return String(parsedValue);
        }
    </script>
</body>

</html>