<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Snowball - 운영평가 가이드</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">

</head>
<body>
    {% include 'navi.jsp' %}
    
    <div class="container-fluid h-100">
        <div class="row h-100">
            <!-- 왼쪽 사이드바 -->
            <div class="col-md-3 col-lg-3 sidebar" style="padding:0;">
                <div id="categoryList"></div>
            </div>
            
            <!-- 오른쪽 컨텐츠 영역 -->
            <div class="col-md-9 col-lg-9 content-area d-flex align-items-stretch h-100" style="padding:0; position: relative;">
                <!-- 템플릿 다운로드 버튼을 별도 컨테이너로 분리 -->
                <div id="template-button-container" style="position: absolute; top: 60px; right: 80px; z-index: 9999;">
                    <a id="template-download-btn" href="#" style="padding: 8px 16px; background: #28a745; color: #fff; border-radius: 4px; text-decoration: none; pointer-events: none; opacity: 0.5;">템플릿 다운로드</a>
                </div>
                <div id="contentContainer" class="flex-grow-1 d-flex flex-column justify-content-center align-items-stretch h-100" style="padding:0;">
                    <div class="text-center text-muted">
                        <h3>항목을 선택해주세요</h3>
                        <p>왼쪽 메뉴에서 원하는 항목을 선택하시면 상세 내용이 표시됩니다.</p>
                    </div>
                </div>
                <!-- AI 샘플데이터 코멘트 -->
                <div style="position: absolute; bottom: 10px; left: 50%; transform: translateX(-50%); z-index: 9999;">
                    <small style="color: #999; font-size: 0.8rem; text-align: center;">해당 데이터는 AI로 생성한 샘플데이터이므로 실제와 다를 수 있습니다</small>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const options = {
            APD: [
                {value: "APD01", text: "Application 권한부여 승인"},
                {value: "APD02", text: "Application 부서이동자 권한 회수"},
                {value: "APD03", text: "Application 퇴사자 접근권한 회수"},
                {value: "APD04", text: "Application 권한 Monitoring"},
                {value: "APD05", text: "Application 관리자 권한 제한"},
                {value: "APD06", text: "Application 패스워드"},
                {value: "APD07", text: "Data 직접변경 승인"},
                {value: "APD08", text: "DB 접근권한 승인"},
                {value: "APD09", text: "DB 패스워드"},
                {value: "APD10", text: "DB 관리자 권한 제한"},
                {value: "APD11", text: "OS 접근권한 승인"},
                {value: "APD12", text: "OS 패스워드"},
                {value: "APD13", text: "OS 관리자 권한 제한"}
            ],
            PC: [
                {value: "PC01", text: "프로그램 변경"},
                {value: "PC04", text: "이관담당자 권한 제한"},
                {value: "PC05", text: "개발/운영 환경 분리"},
                {value: "PC06", text: "DB 설정 변경"},
                {value: "PC07", text: "OS 설정 변경"}
            ],
            CO: [
                {value: "CO01", text: "배치잡 스케줄 등록 승인"},
                {value: "CO02", text: "배치잡 스케줄 등록 권한 제한"},
                {value: "CO03", text: "배치잡 스케줄 등록 Monitoring"},
                {value: "CO04", text: "백업 Monitoring"},
                {value: "CO05", text: "장애관리"},
                {value: "CO06", text: "서버실 접근 제한"}
                
            ]
        };

        const categoryNames = {
            'APD': 'Access Program & Data',
            'PC': 'Program Changes',
            'CO': 'Computer Operations'
        };

        function updateTemplateButton(selectedValue) {
            const btn = document.getElementById('template-download-btn');
            if (!selectedValue) {
                btn.href = "#";
                btn.style.pointerEvents = "none";
                btn.style.opacity = "0.5";
                return;
            }
            btn.href = `/static/paper/${selectedValue}_paper.xlsx`;
            btn.style.pointerEvents = "auto";
            btn.style.opacity = "1";
        }

        function initializeSidebar() {
            const categoryList = document.getElementById('categoryList');
            categoryList.innerHTML = '';

            Object.keys(options).forEach(category => {
                const categoryTitle = document.createElement('div');
                categoryTitle.className = 'category-title';
                categoryTitle.innerHTML = `
                    ${categoryNames[category]}
                    <i class="fas fa-chevron-down"></i>
                `;
                
                const optionList = document.createElement('div');
                optionList.className = 'option-list';
                
                options[category].forEach(option => {
                    const link = document.createElement('a');
                    link.href = '#';
                    link.className = 'nav-link';
                    link.dataset.value = option.value;
                    link.textContent = option.text;
                    
                    link.addEventListener('click', function(e) {
                        document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
                        this.classList.add('active');
                        updateContent(this.dataset.value);
                        updateTemplateButton(this.dataset.value); // 버튼 동적 변경
                    });
                    
                    optionList.appendChild(link);
                });
                
                categoryTitle.addEventListener('click', function() {
                    this.classList.toggle('collapsed');
                    optionList.classList.toggle('show');
                });
                
                categoryList.appendChild(categoryTitle);
                categoryList.appendChild(optionList);
            });
        }

        document.addEventListener('DOMContentLoaded', function() {
            initializeSidebar();
            updateTemplateButton(null); // 초기 비활성화
        });

        function updateContent(selectedValue) {
            const contentContainer = document.getElementById('contentContainer');
            const templateButtonContainer = document.getElementById('template-button-container');
            
            // 버튼 컨테이너는 건드리지 않고 contentContainer만 업데이트
            contentContainer.innerHTML = '';

            // step-by-step 컨텐츠 생성
            contentContainer.innerHTML = `
                <div class="step-card flex-grow-1 d-flex flex-column align-items-center justify-content-center">
                    <div id="step-img" class="text-center"></div>
                    <div id="step-title" class="text-center mt-3 mb-2" style="font-weight:bold;font-size:1.2em;"></div>
                    <div id="step-desc" class="text-start mb-3" style="max-width:900px;width:100%;margin:0 auto;"></div>
                    <div id="step-indicator" class="text-center mb-3"></div>
                    <div class="step-btns d-flex justify-content-center">
                        <button id="prev-btn" class="btn btn-sm btn-outline-secondary me-2">이전</button>
                        <button id="next-btn" class="btn btn-sm btn-outline-light">다음</button>
                    </div>
                </div>
            `;
            enableStepByStep(selectedValue);
        }

        // 모든 메뉴에 대해 step-by-step 로직
        function enableStepByStep(type) {
            // 각 항목별 step 데이터 정의
                const stepMap = {
                APD01: [
                    {img: "/static/img/Operation/APD01_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 권한부여 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD01_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/APD01_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 권한부여 일자와 승인 일자를 비교하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서에 Testing Table에 추가합니다."}
                ],
                APD02: [
                    {img: "/static/img/Operation/APD02_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 부서이동자 명단)을 시스템 또는 인사자료에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD02_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table에 작성합니다."},
                    {img: "/static/img/Operation/APD02_Step3.jpg", title: "Step 3: 권한 회수 여부 점검", desc: "1. 부서이동일 이후 기존 권한의 회수 여부를 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 추가합니다."}
                ],
                APD03: [
                    {img: "/static/img/Operation/APD03_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 퇴사자 명단)을 시스템 또는 인사자료에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD03_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table에 작성합니다."},
                    {img: "/static/img/Operation/APD03_Step3.jpg", title: "Step 3: 권한 회수 여부 점검", desc: "1. 퇴사일 이후 접근 권한 회수여부를 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 추가합니다."}
                ],
                APD04: [
                    {img: "/static/img/Operation/APD04_Step1.jpg", title: "Step 1: 권한 모니터링 문서 확보 및 검토", desc: "1. 당기 권한 모니터링 문서를 확보합니다.<br>2. 문서에 전체 사용자 및 모든 권한이 포함되어 있는지 확인합니다.<br>3. 부적절한 권한이 탐지된 경우 회수 등 적절한 조치 여부에 대해 확인합니다."},
                    {img: "/static/img/Operation/APD04_Step2.jpg", title: "Step 2: 샘플 선정 및 승인 여부 확인", desc: "1. 통제 주기에 따라 샘플 수를 선정합니다.<br>2. 선정된 샘플에 대해 적절한 승인(결재)이 이루어졌는지 확인합니다.<br>3. 결과를 운영평가 조서의 Testing Table에 작성합니다."},
                ],
                APD05: [
                    {img: "/static/img/Operation/APD05_Step1.jpg", title: "Step 1: 관리자 계정 확인", desc: "1. 관리자 권한을 보유하고 있는 계정을 시스템에서 추출합니다."},
                    {img: "/static/img/Operation/APD05_Step2.jpg", title: "Step 2: 권한 보유자 적정성 검토", desc: "1. 추출된 사용자의 부서, 직무, 담당 업무 등을 검토하여 권한 보유의 적정성을 확인합니다.<br>2. 검토 결과를 운영평가 조서에 작성합니다."},
                ],
                APD06: [
                    {img: "/static/img/Operation/APD06_Step1.jpg", title: "Step 1: 보안규정 및 정책서 확인", desc: "1. 회사의 보안규정 또는 정책서에 패스워드 관련 사항이 명시되어 있는지 확인합니다."},
                    {img: "/static/img/Operation/APD06_Step2.jpg", title: "Step 2: 정책 부합 여부 점검", desc: "1. 실제 시스템의 패스워드 설정이 정책서 기준(예: 최소 길이, 복잡성 등)에 부합하는지 확인합니다.<br>2. 시스템 설정 화면을 캡쳐하여 증빙으로 확보합니다.<br>3. 별도의 규정이 없는 경우, 최소 8자리 및 문자/숫자/특수문자 조합 등 기본 복잡성 요건이 적용되어 있는지 확인합니다.<br>4. 결과를 운영평가 조서의 Testing Table 시트에 작성합니다."},
                ],
                APD07: [
                    {img: "/static/img/Operation/APD07_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 데이터 변경 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. DB에 접속하여 쿼리를 통해 데이터를 변경한 내역(Insert, Update, Delete)을 대상으로 하며 시스템이 생성한 쿼리는 제외합니다.<br>4. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD07_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table에 작성합니다."},
                    {img: "/static/img/Operation/APD07_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 데이터 변경 일자와 승인 일자를 비교하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table에 추가합니다."},
                ],
                APD08: [
                    {img: "/static/img/Operation/APD08_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 DB 접근권한 부여 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD08_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/APD08_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 확인합니다.<br>2. 권한 부여 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table에 추가합니다."},
                ],
                APD09: [
                    {img: "/static/img/Operation/APD09_Step1.jpg", title: "Step 1: 보안규정 및 정책서 확인", desc: "1. 회사의 보안규정 또는 정책서에 패스워드 관련 사항이 명시되어 있는지 확인합니다."},
                    {img: "/static/img/Operation/APD09_Step2.jpg", title: "Step 2: 정책 부합 여부 점검", desc: "1. 실제 시스템의 패스워드 설정이 정책서 기준(예: 최소 길이, 복잡성 등)에 부합하는지 확인합니다.<br>2. 시스템 설정 화면을 캡쳐하여 증빙으로 확보합니다.<br>3. 별도의 규정이 없는 경우, 최소 8자리 및 문자/숫자/특수문자 조합 등 기본 복잡성 요건이 적용되어 있는지 확인합니다.<br>4. 결과를 운영평가 조서의 Testing Table 시트에 작성합니다."},
                ],
                APD10: [
                    {img: "/static/img/Operation/APD10_Step1.jpg", title: "Step 1: 관리자 계정 확인", desc: "1. 관리자 권한을 보유하고 있는 계정을 시스템에서 추출합니다."},
                    {img: "/static/img/Operation/APD10_Step2.jpg", title: "Step 2: 권한 보유자 적정성 검토", desc: "1. 추출된 사용자의 부서, 직무, 담당 업무 등을 검토하여 권한 보유의 적정성을 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 작성합니다."},
                ],
                APD11: [
                    {img: "/static/img/Operation/APD11_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 OS 접근권한 부여 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/APD11_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/APD11_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 확인합니다.<br>2. 권한 부여 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table에 추가합니다."},
                ],
                APD12: [
                    {img: "/static/img/Operation/APD12_Step1.jpg", title: "Step 1: 보안규정 및 정책서 확인", desc: "1. 회사의 보안규정 또는 정책서에 OS 패스워드 관련 사항이 명시되어 있는지 확인합니다."},
                    {img: "/static/img/Operation/APD12_Step2.jpg", title: "Step 2: 정책 부합 여부 점검", desc: "1. 실제 시스템의 패스워드 설정이 정책서 기준(예: 최소 길이, 복잡성 등)에 부합하는지 확인합니다.<br>2. 시스템 설정 화면을 캡쳐하여 증빙으로 확보합니다.<br>3. 별도의 규정이 없는 경우, 최소 8자리 및 문자/숫자/특수문자 조합 등 기본 복잡성 요건이 적용되어 있는지 확인합니다.<br>4. 결과를 운영평가 조서의 Testing Table 시트에 작성합니다."},
                ],
                APD13: [
                    {img: "/static/img/Operation/APD13_Step1.jpg", title: "Step 1: 관리자 계정 확인", desc: "1. 관리자 권한을 보유하고 있는 계정을 시스템에서 추출합니다."},
                    {img: "/static/img/Operation/APD13_Step2.jpg", title: "Step 2: 권한 보유자 적정성 검토", desc: "1. 추출된 사용자의 부서, 직무, 담당 업무 등을 검토하여 권한 보유의 적정성을 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 작성합니다."},
                ],
                PC01: [
                    {img: "/static/img/Operation/PC01_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 프로그램 이관 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/PC01_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/PC01_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(변경 요청에 대한 승인, 사용자 테스트 유무, 이관 요청에 대한 승인)을 검토합니다.<br>2. 프로그램 이관 일자와 각 증빙 일자를 비교하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table 시트에 추가합니다.<br> * 프로그램 변경 승인, 프로그램 변경 사용자 테스트, 프로그램 이관 승인은 별개의 통제이나 테스트는 함께 진행할 수 있습니다."}
                ],
                PC04: [
                    {img: "/static/img/Operation/PC04_Step1.jpg", title: "Step 1: 이관권한자 계정 확인", desc: "1. 이관권한을 보유하고 있는 계정을 시스템에서 추출합니다."},
                    {img: "/static/img/Operation/PC04_Step2.jpg", title: "Step 2: 권한 보유자 적정성 검토", desc: "1. 추출된 사용자의 부서, 직무, 담당 업무 등을 검토하여 권한 보유의 적정성을 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 작성합니다."},
                ],
                PC05: [
                    {img: "/static/img/Operation/PC05_Step1.jpg", title: "Step 1: 개발/운영 환경 분리 현황 확인", desc: "1. 시스템이 운영환경과 별도의 개발환경을 보유하고 있는지 확인합니다."},
                    {img: "/static/img/Operation/PC05_Step2.jpg", title: "Step 2: 증빙 자료 확보", desc: "1. 서버 구성도, IP 목록 등으로 개발환경과 운영환경이 분리되어 있는지 증빙 자료를 확보합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table에 작성합니다."},
                ],
                PC06: [
                    {img: "/static/img/Operation/PC07_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 DB 패치 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 패치 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table 시트에 추가합니다."},
                ],
                PC07: [
                    {img: "/static/img/Operation/PC07_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 OS 패치 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 패치 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table 시트에 추가합니다."},
                ],
                PC08: [
                    {img: "/static/img/Operation/PC07_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 Application 패치 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/PC07_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 패치 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table 시트에 추가합니다."},
                ],
                CO01: [
                    {img: "/static/img/Operation/CO01_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 해당 통제의 모집단(당기 Batch Schedule 등록 이력)을 시스템에서 추출합니다.<br>2. 추출 시점의 데이터 건수와 캡쳐 화면을 확보하여 완전성을 확인합니다.<br>3. 운영평가 조서의 Population 시트를 선택하여 모집단 데이터와 캡쳐 화면을 작성합니다."},
                    {img: "/static/img/Operation/CO01_Step2.jpg", title: "Step 2: 샘플 선정", desc: "1. 모집단 수에 따라 샘플 수를 결정합니다.<br>(예: 모집단이 10개인 경우 Quarterly와 Monthly 사이이므로 2개, 13개인 경우 Monthly와 Weekly 사이이므로 5개 선정 등)<br>2. 샘플 선정은 무작위 표본추출(Simple Random Sampling) 방식으로 해야 하며, 임의의 데이터를 선택하면 안됩니다.<br>3. 선정된 샘플만 운영평가 조서의 Testing Table 시트에 작성합니다."},
                    {img: "/static/img/Operation/CO01_Step3.jpg", title: "Step 3: 증빙 확인", desc: "1. 선정된 샘플에 대한 증빙(승인 내역)을 검토합니다.<br>2. 배치 스케줄 등록 일자와 승인 일자를 대사하여 사전 승인 여부를 확인합니다.<br>3. 검토 결과를 운영평가 조서의 Testing Table 시트에 추가합니다."},
                ],
                CO02: [
                    {img: "/static/img/Operation/CO02_Step1.jpg", title: "Step 1: Batch Schedule 등록 계정 확인", desc: "1. Batch Schedule 등록 권한을 보유하고 있는 계정을 시스템에서 추출합니다."},
                    {img: "/static/img/Operation/CO02_Step2.jpg", title: "Step 2: 권한 보유자 적정성 검토", desc: "1. 추출된 사용자의 부서, 직무, 담당 업무 등을 검토하여 권한 보유의 적정성을 확인합니다.<br>2. 검토 결과를 운영평가 조서의 Testing Table 시트에 작성합니다."},
                ],
                CO03: [
                    {img: "/static/img/Operation/CO03_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 배치잡 스케줄 실행 중 오류 내역을 추출합니다.<br>2. 추출 시점의 실행 내역과 캡쳐 화면을 확보하여 완전성을 확인합니다."},
                    {img: "/static/img/Operation/CO03_Step2.jpg", title: "Step 2: 증빙 확인", desc: "1. 오류 발생 시 원인 분석 및 조치 내역을 확인합니다.<br>2. 오류에 대한 조치와 기록이 적절하게 남아 있는지 확인합니다."},
                ],
                CO04: [
                    {img: "/static/img/Operation/CO04_Step1.jpg", title: "Step 1: 모니터링 문서 확보 및 검토", desc: "1. 당기 백업 모니터링 문서를 확보합니다.<br>2. 문서에 In-Scope System의 포함여부를 확인합니다.<br>3. 오류가 있었을 경우 적시에 적절한 조치가 이루어졌는지 확인합니다.<br>4. 설계된 통제주기(연, 분기 등)에 따라 모집단의 완전성을 확인합니다."},
                    {img: "/static/img/Operation/CO04_Step2.jpg", title: "Step 2: 샘플 선정 및 승인 여부 확인", desc: "1. 통제 주기에 따라 샘플 수를 선정합니다.<br>2. 선정된 샘플에 대해 적절한 승인(결재)이 이루어졌는지 확인합니다."},
                ],
                CO05: [
                    {img: "/static/img/Operation/CO05_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 장애 발생 내역을 확보합니다.<br>- 장애이력은 시스템에 기록되지 않을 수 있으므로 수기대장도 모집단으로 사용합니다."},
                    {img: "/static/img/Operation/CO05_Step2.jpg", title: "Step 2: 증빙 확인", desc: "1. 장애에 대한 조치 내역이 적절하게 기록되어 있는지 확인합니다."},
                ],
                CO06: [
                    {img: "/static/img/Operation/CO06_Step1.jpg", title: "Step 1: 모집단 확인", desc: "1. 서버실 출입 요청 및 출입 내역을 시스템에서 추출합니다.<br>2. 추출 시점의 출입 내역과 캡쳐 화면을 확보하여 완전성을 확인합니다."},
                    {img: "/static/img/Operation/CO06_Step2.jpg", title: "Step 2: 증빙 확인", desc: "1. 출입 요청에 대한 승인 내역과 출입 기록이 적절하게 남아 있는지 확인합니다."},
                ],
            };
            const steps = stepMap[type];
            if (!steps) return;
            let currentStep = 0;
            const imgDiv = document.getElementById('step-img');
            const titleDiv = document.getElementById('step-title');
            const descDiv = document.getElementById('step-desc');
            const indicatorDiv = document.getElementById('step-indicator');
            const prevBtn = document.getElementById('prev-btn');
            const nextBtn = document.getElementById('next-btn');
            if (!imgDiv || !titleDiv || !descDiv || !indicatorDiv || !prevBtn || !nextBtn) return;
            function renderStep() {
                if (steps[currentStep].img) {
                    imgDiv.innerHTML = `<img src="${steps[currentStep].img}" alt="step image" class="step-img-el">`;
                } else {
                    imgDiv.textContent = steps[currentStep].title.split(':')[0].toUpperCase();
                }
                titleDiv.textContent = steps[currentStep].title;
                descDiv.innerHTML = steps[currentStep].desc;
                const indicator = steps.map((_, idx) => `<span class="${idx === currentStep ? 'active' : ''}"></span>`).join('');
                indicatorDiv.innerHTML = indicator;
                prevBtn.disabled = currentStep === 0;
                nextBtn.disabled = currentStep === steps.length - 1;
                resizeStepCard();
            }
            prevBtn.onclick = function() {
                if (currentStep > 0) {
                    currentStep--;
                    renderStep();
                }
            };
            nextBtn.onclick = function() {
                if (currentStep < steps.length - 1) {
                    currentStep++;
                    renderStep();
                }
            };
            renderStep();
            setTimeout(resizeStepCard, 100);
        }

        // step-card가 부모 영역을 무조건 꽉 채우도록 JS로 강제 (전역 1회 등록)
        function resizeStepCard() {
            const area = document.querySelector('.content-area');
            const card = document.querySelector('.step-card');
            if (area && card) {
                card.style.height = area.offsetHeight + 'px';
            }
        }
        window.addEventListener('resize', resizeStepCard);
    </script>
</body>
</html>