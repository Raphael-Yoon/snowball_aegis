<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Snowball - 영상 가이드</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
</head>
<body>
    {% include 'navi.jsp' %}
    
    <div class="container-fluid">
        <div class="row">
            <!-- 왼쪽 사이드바 -->
            <div class="col-md-4 col-lg-3 sidebar">
                <div id="categoryList"></div>
            </div>
            
            <!-- 오른쪽 컨텐츠 영역 -->
            <div class="col-md-8 col-lg-9 content-area">
                <div id="contentContainer">
                    <div class="text-center text-muted">
                        <h3>항목을 선택해주세요</h3>
                        <p>왼쪽 메뉴에서 원하는 항목을 선택하시면 상세 내용이 표시됩니다.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const options = {
            ITPWC: [
                {value: "OVERVIEW", text: "내부회계관리제도 Overview"},
                {value: "ITPWC01", text: "ITGC Scoping"}
            ],
            ITGC: [
                {value: "APD01", text: "Application 권한부여 승인"},
                {value: "APD02", text: "Application 부서이동자 권한 회수"},
                {value: "APD03", text: "Application 퇴사자 접근권한 회수"},
                {value: "APD07", text: "Data 직접변경 승인"},
                {value: "APD08", text: "서버(OS/DB) 접근권한 승인"},
                {value: "PC01", text: "프로그램 변경"},
                {value: "CO01", text: "배치잡 스케줄 등록 승인"}
            ],
            ETC: [
                {value: "PW", text: "패스워드 기준"},
                {value: "PW_DETAIL", text: "패스워드 기준 상세"},
                {value: "MONITOR", text: "데이터 변경 모니터링"},
                {value: "DDL", text: "DDL 변경 통제"}
            ]
        };

        const categoryNames = {
            'ITPWC': 'IT Process Wide Controls',
            'ITGC': 'IT General Controls',
            'ETC': '기타'
        };

        // 영상 제작 중인 항목 (사이드바 비활성화 + 준비 중 메시지)
        const preparingList = ['APD07', 'APD08', 'PC01', 'CO01'];

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

                    if (preparingList.includes(option.value)) {
                        link.classList.add('disabled-link');
                    }

                    link.addEventListener('click', function(e) {
                        document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
                        this.classList.add('active');
                        updateContent(this.dataset.value);
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

        function updateContent(selectedValue) {
            const contentContainer = document.getElementById('contentContainer');
            contentContainer.innerHTML = '';

            if (preparingList.includes(selectedValue)) {
                contentContainer.innerHTML = `
                    <div style="text-align: center; padding: 20px;">
                        <h3>준비 중입니다</h3>
                        <p>해당 항목은 현재 영상제작 중 입니다.</p>
                    </div>
                `;
                return;
            }

            fetch(`/get_content_link4?type=${selectedValue}`)
                .then(response => response.text())
                .then(html => {
                    contentContainer.innerHTML = html;
                })
                .catch(error => {
                    console.error('Error:', error);
                    contentContainer.innerHTML = `
                        <div class="alert alert-danger" role="alert">
                            <h4 class="alert-heading">오류가 발생했습니다</h4>
                            <p>페이지를 불러오는 중 문제가 발생했습니다.</p>
                        </div>
                    `;
                });
        }

        document.addEventListener('DOMContentLoaded', initializeSidebar);
    </script>
</body>
</html>