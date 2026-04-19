<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - 내 RCM 조회</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    {% include 'navi.jsp' %}

    <!-- Toast Container -->
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1100;">
        <div id="successToast" class="toast align-items-center text-bg-success border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="fas fa-check-circle me-2"></i><span id="toastMessage"></span>
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    </div>

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><img src="{{ url_for('static', filename='img/rcm.jpg') }}" alt="RCM" style="width: 40px; height: 40px; object-fit: cover; border-radius: 8px; margin-right: 12px;">내 RCM 조회/평가</h1>
                    <div>
                        <a href="{{ url_for('link5.rcm_upload') }}" class="btn btn-gradient me-2">
                            <i class="fas fa-upload me-1"></i>RCM 업로드
                        </a>
                        <a href="/" class="btn btn-secondary">
                            <i class="fas fa-home me-1"></i>홈으로
                        </a>
                    </div>
                </div>
                <hr>
            </div>
        </div>

        {% if user_rcms %}
        <!-- 카테고리 탭 -->
        <ul class="nav nav-tabs mb-4" id="rcmTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="all-tab" data-bs-toggle="tab" data-bs-target="#all" type="button">
                    전체 ({{ user_rcms|length }})
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="elc-tab" data-bs-toggle="tab" data-bs-target="#elc" type="button">
                    ELC ({{ rcms_by_category.ELC|length }})
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tlc-tab" data-bs-toggle="tab" data-bs-target="#tlc" type="button">
                    TLC ({{ rcms_by_category.TLC|length }})
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="itgc-tab" data-bs-toggle="tab" data-bs-target="#itgc" type="button">
                    ITGC ({{ rcms_by_category.ITGC|length }})
                </button>
            </li>
        </ul>

        <!-- 탭 콘텐츠 -->
        <div class="tab-content" id="rcmTabsContent">
            <!-- 전체 탭 -->
            <div class="tab-pane fade show active" id="all" role="tabpanel">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-list me-2"></i>접근 가능한 RCM 목록 (전체)</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th>카테고리</th>
                                        <th>RCM명</th>
                                        <th>회사명</th>
                                        <th>설명</th>
                                        <th>내 권한</th>
                                        <th>업로드일</th>
                                        <th>평가 세션</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for rcm in user_rcms %}
                                    <tr>
                                        <td>
                                            {% if rcm.control_category == 'ELC' %}
                                            <span class="badge bg-primary">ELC</span>
                                            {% elif rcm.control_category == 'TLC' %}
                                            <span class="badge bg-success">TLC</span>
                                            {% else %}
                                            <span class="badge bg-info">ITGC</span>
                                            {% endif %}
                                        </td>
                                        <td id="rcm-name-{{ rcm.rcm_id }}">
                                            <strong class="rcm-name-display" data-rcm-id="{{ rcm.rcm_id }}" data-original-name="{{ rcm.rcm_name }}" ondblclick="editRcmName(this)" style="cursor: pointer;" title="더블클릭하여 수정">{{ rcm.rcm_name }}</strong>
                                            <input type="text" class="form-control form-control-sm rcm-name-edit d-none" value="{{ rcm.rcm_name }}" data-rcm-id="{{ rcm.rcm_id }}" onblur="cancelEditRcmName(this)" onkeypress="if(event.key==='Enter') saveRcmName(this); else if(event.key==='Escape') cancelEditRcmName(this);">
                                        </td>
                                        <td>{{ rcm.company_name }}</td>
                                        <td>{{ rcm.description or '-' }}</td>
                                        <td>
                                            <span class="badge bg-{{ 'danger' if rcm.permission_type == 'admin' else 'success' }}">
                                                {{ '관리자' if rcm.permission_type == 'admin' else '읽기' }}
                                            </span>
                                        </td>
                                        <td>{{ rcm.upload_date.split(' ')[0] if rcm.upload_date else '-' }}</td>
                                        <td><small class="text-muted">{{ rcm.evaluation_session }}</small></td>
                                        <td>
                                            <a href="{{ rcm.action_url }}" class="btn btn-sm {{ rcm.action_class }} me-1" style="min-width: 110px; display: inline-block; text-align: center;">
                                                <i class="fas fa-{{ 'play' if 'continue' in rcm.action_type else 'plus' }} me-1"></i>{{ rcm.action_label }}
                                            </a>
                                            <a href="/rcm/{{ rcm.rcm_id }}/select" class="btn btn-sm btn-outline-secondary me-1">
                                                <i class="fas fa-eye me-1"></i>상세
                                            </a>
                                            {% if user_info and (user_info.get('admin_flag') == 'Y' or rcm.permission_type == 'admin') %}
                                            <a href="/admin/rcm/{{ rcm.rcm_id }}/users" class="btn btn-sm btn-outline-info me-1">
                                                <i class="fas fa-users me-1"></i>접근 관리
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                            {% endif %}
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ELC 탭 -->
            <div class="tab-pane fade" id="elc" role="tabpanel">
                <div class="card">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0"><i class="fas fa-building me-2"></i>ELC - Entity Level Controls (전사적 통제)</h5>
                    </div>
                    <div class="card-body">
                        {% if rcms_by_category.ELC %}
                        <div class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th>RCM명</th>
                                        <th>회사명</th>
                                        <th>설명</th>
                                        <th>내 권한</th>
                                        <th>업로드일</th>
                                        <th>평가 세션</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for rcm in rcms_by_category.ELC %}
                                    <tr>
                                        <td id="rcm-name-{{ rcm.rcm_id }}">
                                            <strong class="rcm-name-display" data-rcm-id="{{ rcm.rcm_id }}" data-original-name="{{ rcm.rcm_name }}" ondblclick="editRcmName(this)" style="cursor: pointer;" title="더블클릭하여 수정">{{ rcm.rcm_name }}</strong>
                                            <input type="text" class="form-control form-control-sm rcm-name-edit d-none" value="{{ rcm.rcm_name }}" data-rcm-id="{{ rcm.rcm_id }}" onblur="cancelEditRcmName(this)" onkeypress="if(event.key==='Enter') saveRcmName(this); else if(event.key==='Escape') cancelEditRcmName(this);">
                                        </td>
                                        <td>{{ rcm.company_name }}</td>
                                        <td>{{ rcm.description or '-' }}</td>
                                        <td>
                                            <span class="badge bg-{{ 'danger' if rcm.permission_type == 'admin' else 'success' }}">
                                                {{ '관리자' if rcm.permission_type == 'admin' else '읽기' }}
                                            </span>
                                        </td>
                                        <td>{{ rcm.upload_date.split(' ')[0] if rcm.upload_date else '-' }}</td>
                                        <td><small class="text-muted">{{ rcm.evaluation_session }}</small></td>
                                        <td>
                                            <a href="{{ rcm.action_url }}" class="btn btn-sm {{ rcm.action_class }} me-1" style="min-width: 110px; display: inline-block; text-align: center;">
                                                <i class="fas fa-{{ 'play' if 'continue' in rcm.action_type else 'plus' }} me-1"></i>{{ rcm.action_label }}
                                            </a>
                                            <a href="/rcm/{{ rcm.rcm_id }}/select" class="btn btn-sm btn-outline-secondary me-1">
                                                <i class="fas fa-eye me-1"></i>상세
                                            </a>
                                            {% if user_info and (user_info.get('admin_flag') == 'Y' or rcm.permission_type == 'admin') %}
                                            <a href="/admin/rcm/{{ rcm.rcm_id }}/users" class="btn btn-sm btn-outline-info me-1">
                                                <i class="fas fa-users me-1"></i>접근 관리
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                            {% endif %}
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">ELC RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>

            <!-- TLC 탭 -->
            <div class="tab-pane fade" id="tlc" role="tabpanel">
                <div class="card">
                    <div class="card-header bg-success text-white">
                        <h5 class="mb-0"><i class="fas fa-exchange-alt me-2"></i>TLC - Transaction Level Controls (거래 수준 통제)</h5>
                    </div>
                    <div class="card-body">
                        {% if rcms_by_category.TLC %}
                        <div class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th>RCM명</th>
                                        <th>회사명</th>
                                        <th>설명</th>
                                        <th>내 권한</th>
                                        <th>업로드일</th>
                                        <th>평가 세션</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for rcm in rcms_by_category.TLC %}
                                    <tr>
                                        <td id="rcm-name-{{ rcm.rcm_id }}">
                                            <strong class="rcm-name-display" data-rcm-id="{{ rcm.rcm_id }}" data-original-name="{{ rcm.rcm_name }}" ondblclick="editRcmName(this)" style="cursor: pointer;" title="더블클릭하여 수정">{{ rcm.rcm_name }}</strong>
                                            <input type="text" class="form-control form-control-sm rcm-name-edit d-none" value="{{ rcm.rcm_name }}" data-rcm-id="{{ rcm.rcm_id }}" onblur="cancelEditRcmName(this)" onkeypress="if(event.key==='Enter') saveRcmName(this); else if(event.key==='Escape') cancelEditRcmName(this);">
                                        </td>
                                        <td>{{ rcm.company_name }}</td>
                                        <td>{{ rcm.description or '-' }}</td>
                                        <td>
                                            <span class="badge bg-{{ 'danger' if rcm.permission_type == 'admin' else 'success' }}">
                                                {{ '관리자' if rcm.permission_type == 'admin' else '읽기' }}
                                            </span>
                                        </td>
                                        <td>{{ rcm.upload_date.split(' ')[0] if rcm.upload_date else '-' }}</td>
                                        <td><small class="text-muted">{{ rcm.evaluation_session }}</small></td>
                                        <td>
                                            <a href="{{ rcm.action_url }}" class="btn btn-sm {{ rcm.action_class }} me-1" style="min-width: 110px; display: inline-block; text-align: center;">
                                                <i class="fas fa-{{ 'play' if 'continue' in rcm.action_type else 'plus' }} me-1"></i>{{ rcm.action_label }}
                                            </a>
                                            <a href="/rcm/{{ rcm.rcm_id }}/select" class="btn btn-sm btn-outline-secondary me-1">
                                                <i class="fas fa-eye me-1"></i>상세
                                            </a>
                                            {% if user_info and (user_info.get('admin_flag') == 'Y' or rcm.permission_type == 'admin') %}
                                            <a href="/admin/rcm/{{ rcm.rcm_id }}/users" class="btn btn-sm btn-outline-info me-1">
                                                <i class="fas fa-users me-1"></i>접근 관리
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                            {% endif %}
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">TLC RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>

            <!-- ITGC 탭 -->
            <div class="tab-pane fade" id="itgc" role="tabpanel">
                <div class="card">
                    <div class="card-header bg-info text-white">
                        <h5 class="mb-0"><i class="fas fa-server me-2"></i>ITGC - IT General Controls (IT 일반 통제)</h5>
                    </div>
                    <div class="card-body">
                        {% if rcms_by_category.ITGC %}
                        <div class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th>RCM명</th>
                                        <th>회사명</th>
                                        <th>설명</th>
                                        <th>내 권한</th>
                                        <th>업로드일</th>
                                        <th>평가 세션</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for rcm in rcms_by_category.ITGC %}
                                    <tr>
                                        <td id="rcm-name-{{ rcm.rcm_id }}">
                                            <strong class="rcm-name-display" data-rcm-id="{{ rcm.rcm_id }}" data-original-name="{{ rcm.rcm_name }}" ondblclick="editRcmName(this)" style="cursor: pointer;" title="더블클릭하여 수정">{{ rcm.rcm_name }}</strong>
                                            <input type="text" class="form-control form-control-sm rcm-name-edit d-none" value="{{ rcm.rcm_name }}" data-rcm-id="{{ rcm.rcm_id }}" onblur="cancelEditRcmName(this)" onkeypress="if(event.key==='Enter') saveRcmName(this); else if(event.key==='Escape') cancelEditRcmName(this);">
                                        </td>
                                        <td>{{ rcm.company_name }}</td>
                                        <td>{{ rcm.description or '-' }}</td>
                                        <td>
                                            <span class="badge bg-{{ 'danger' if rcm.permission_type == 'admin' else 'success' }}">
                                                {{ '관리자' if rcm.permission_type == 'admin' else '읽기' }}
                                            </span>
                                        </td>
                                        <td>{{ rcm.upload_date.split(' ')[0] if rcm.upload_date else '-' }}</td>
                                        <td><small class="text-muted">{{ rcm.evaluation_session }}</small></td>
                                        <td>
                                            <a href="{{ rcm.action_url }}" class="btn btn-sm {{ rcm.action_class }} me-1" style="min-width: 110px; display: inline-block; text-align: center;">
                                                <i class="fas fa-{{ 'play' if 'continue' in rcm.action_type else 'plus' }} me-1"></i>{{ rcm.action_label }}
                                            </a>
                                            <a href="/rcm/{{ rcm.rcm_id }}/select" class="btn btn-sm btn-outline-secondary me-1">
                                                <i class="fas fa-eye me-1"></i>상세
                                            </a>
                                            {% if user_info and (user_info.get('admin_flag') == 'Y' or rcm.permission_type == 'admin') %}
                                            <a href="/admin/rcm/{{ rcm.rcm_id }}/users" class="btn btn-sm btn-outline-info me-1">
                                                <i class="fas fa-users me-1"></i>접근 관리
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                            {% endif %}
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">ITGC RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
        {% else %}
        <div class="row">
            <div class="col-12">
                <div class="alert alert-info text-center">
                    <i class="fas fa-info-circle fa-2x mb-3"></i>
                    <h5>접근 가능한 RCM이 없습니다</h5>
                    <p>현재 귀하에게 할당된 RCM이 없습니다. 관리자에게 문의하여 필요한 RCM에 대한 접근 권한을 요청하세요.</p>
                    <hr>
                    <small class="text-muted">
                        <i class="fas fa-question-circle me-1"></i>
                        RCM 접근 권한 관련 문의는 시스템 관리자에게 연락하세요.
                    </small>
                </div>
            </div>
        </div>
        {% endif %}

        <!-- 관리자만 안내사항 표시 -->
        {% if user_info and user_info.get('admin_flag') == 'Y' %}
        <div class="row mt-4">
            <div class="col-12">
                <div class="card">
                    <div class="card-body">
                        <h6><i class="fas fa-info-circle me-2"></i>안내사항</h6>
                        <ul class="list-unstyled small">
                            <li><i class="fas fa-eye text-success me-2"></i><strong>읽기 권한:</strong> RCM 데이터 조회 및 Excel 다운로드</li>
                            <li><i class="fas fa-user-shield text-danger me-2"></i><strong>관리자 권한:</strong> RCM 데이터 조회, 다운로드 및 관리</li>
                            <li><i class="fas fa-shield-alt text-info me-2"></i>모든 RCM 접근은 로그로 기록됩니다.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
        {% endif %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // 토스트 메시지 표시 함수
        function showToast(message, type = 'success') {
            const toast = document.getElementById('successToast');
            const toastMessage = document.getElementById('toastMessage');

            // 타입에 따라 배경색 변경
            toast.classList.remove('text-bg-success', 'text-bg-danger', 'text-bg-warning', 'text-bg-info');
            toast.classList.add('text-bg-' + type);

            toastMessage.textContent = message;
            const bsToast = new bootstrap.Toast(toast, { delay: 3000 });
            bsToast.show();
        }

        // Bootstrap 툴팁 초기화
        document.addEventListener('DOMContentLoaded', function() {
            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });
        });

        function deleteRcm(rcmId, rcmName, force = false) {
            if (!force && !confirm(`"${rcmName}" RCM을 삭제하시겠습니까?\n\n삭제된 RCM은 목록에서 제거됩니다.`)) {
                return;
            }

            fetch(`/rcm/${rcmId}/delete`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ force: force })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast(data.message, 'success');
                    setTimeout(() => location.reload(), 1500);
                } else {
                    // 진행 중인 평가가 있는 경우
                    if (data.ongoing_operation) {
                        // 운영평가 진행 중 - 삭제 불가
                        showToast('⛔ ' + data.message, 'danger');
                    } else if (data.ongoing_design && data.require_confirmation) {
                        // 설계평가 진행 중 - 경고 후 재확인
                        if (confirm('⚠️ ' + data.message + '\n\n그래도 삭제하시겠습니까?')) {
                            // 사용자가 확인했으므로 강제 삭제
                            deleteRcm(rcmId, rcmName, true);
                        }
                    } else {
                        showToast('오류: ' + data.message, 'danger');
                    }
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showToast('RCM 삭제 중 오류가 발생했습니다.', 'danger');
            });
        }

        // RCM 이름 수정 모드
        function editRcmName(element) {
            const rcmId = element.dataset.rcmId;
            const originalName = element.dataset.originalName;
            const cell = document.getElementById(`rcm-name-${rcmId}`);
            const display = cell.querySelector('.rcm-name-display');
            const input = cell.querySelector('.rcm-name-edit');

            display.classList.add('d-none');
            input.classList.remove('d-none');
            input.value = originalName;
            input.focus();
            input.select();
        }

        // RCM 이름 수정 취소
        function cancelEditRcmName(element) {
            const rcmId = element.dataset.rcmId;
            const cell = document.getElementById(`rcm-name-${rcmId}`);
            const display = cell.querySelector('.rcm-name-display');
            const input = cell.querySelector('.rcm-name-edit');

            setTimeout(() => {
                input.classList.add('d-none');
                display.classList.remove('d-none');
            }, 200);
        }

        // RCM 이름 저장
        function saveRcmName(element) {
            const rcmId = element.dataset.rcmId;
            const cell = document.getElementById(`rcm-name-${rcmId}`);
            const input = cell.querySelector('.rcm-name-edit');
            const newName = input.value.trim();

            if (!newName) {
                alert('RCM 이름을 입력해주세요.');
                input.focus();
                return;
            }

            const formData = new FormData();
            formData.append('rcm_id', rcmId);
            formData.append('rcm_name', newName);

            fetch('/rcm/update-name', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // 성공 시 화면 업데이트
                    const display = cell.querySelector('.rcm-name-display');
                    display.textContent = newName;
                    display.dataset.originalName = newName;

                    input.classList.add('d-none');
                    display.classList.remove('d-none');
                } else {
                    alert('저장 실패: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('RCM 이름 수정 중 오류가 발생했습니다.');
            });
        }
    </script>
</body>
</html>