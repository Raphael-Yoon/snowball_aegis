<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - 기준통제 관리</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .attribute-badge {
            font-size: 0.75rem;
        }

        /* 버튼 텍스트 수직 정렬 */
        .modal-footer .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        /* 토스트 위치 - 화면 우측 상단 (스크롤과 무관하게 고정) */
        .toast-container {
            position: fixed !important;
            top: 80px !important;
            right: 20px !important;
            z-index: 9999 !important;
        }

        /* 토스트 스타일 개선 */
        #successToast {
            min-width: 300px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h1 class="mb-0"><i class="fas fa-clipboard-check me-2"></i>기준통제 관리</h1>
                    <a href="/admin" class="btn btn-secondary">
                        <i class="fas fa-arrow-left me-2"></i>관리자 대시보드로 돌아가기
                    </a>
                </div>
                <hr>
            </div>
        </div>

        <!-- 기준통제 목록 -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0"><i class="fas fa-list me-2"></i>기준통제 목록 (총 {{ standard_controls|length }}개)</h5>
                        <button class="btn btn-primary btn-sm" onclick="openAddModal()">
                            <i class="fas fa-plus me-1"></i>새 기준통제 추가
                        </button>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped table-hover" id="standardControlsTable">
                                <thead>
                                    <tr>
                                        <th>코드</th>
                                        <th>통제명</th>
                                        <th>카테고리</th>
                                        <th>설명</th>
                                        <th>관리</th>
                                        <th>Attribute</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for sc in standard_controls %}
                                    <tr>
                                        <td><strong>{{ sc.control_code }}</strong></td>
                                        <td>{{ sc.control_name }}</td>
                                        <td>
                                            <span class="badge bg-info">{{ sc.control_category }}</span>
                                        </td>
                                        <td>{{ sc.control_description[:50] if sc.control_description else '-' }}{% if sc.control_description and sc.control_description|length > 50 %}...{% endif %}</td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-warning"
                                                    data-id="{{ sc.std_control_id }}"
                                                    data-code="{{ sc.control_code }}"
                                                    data-name="{{ sc.control_name }}"
                                                    data-category="{{ sc.control_category }}"
                                                    data-description="{{ (sc.control_description or '')|replace('\n', ' ')|replace('\r', '') }}"
                                                    onclick="openEditModalFromData(this)">
                                                <i class="fas fa-edit me-1"></i>수정
                                            </button>
                                            <button class="btn btn-sm btn-outline-danger"
                                                    onclick="deleteControl({{ sc.std_control_id }}, '{{ sc.control_code }}')">
                                                <i class="fas fa-trash me-1"></i>삭제
                                            </button>
                                        </td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-primary"
                                                    onclick="openAttributeModal({{ sc.std_control_id }}, '{{ sc.control_code }}', '{{ sc.control_name }}')">
                                                <i class="fas fa-cog me-1"></i>설정
                                            </button>
                                            {% set attr_count = 0 %}
                                            {% for i in range(10) %}
                                                {% if sc['attribute' ~ i] %}
                                                    {% set attr_count = attr_count + 1 %}
                                                {% endif %}
                                            {% endfor %}
                                            {% if attr_count > 0 %}
                                                <span class="badge bg-success attribute-badge ms-1">{{ attr_count }}개</span>
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
        </div>
    </div>

    <!-- Attribute 설정 모달 -->
    <div class="modal fade" id="attributeModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Attribute 설정</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <h6>통제 정보</h6>
                    <p>
                        <strong>통제코드:</strong> <span id="modal-control-code"></span><br>
                        <strong>통제명:</strong> <span id="modal-control-name"></span>
                    </p>
                    <hr>
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle me-2"></i>
                        이 기준통제에 매핑되는 RCM 통제에 자동으로 적용될 Attribute 템플릿을 설정하세요.
                    </div>
                    <div class="mb-3">
                        <label for="population-attr-count" class="form-label">
                            <strong>모집단 Attribute 개수</strong>
                        </label>
                        <input type="number"
                               class="form-control"
                               id="population-attr-count"
                               min="0"
                               max="10"
                               value="2"
                               style="width: 100px;"
                               placeholder="예: 2">
                        <small class="text-muted">
                            0=모집단 없음(자동통제), 2=attribute0~1은 모집단, attribute2~9는 증빙
                        </small>
                    </div>
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th width="15%">구분</th>
                                <th width="20%">Attribute</th>
                                <th width="65%">필드명</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for i in range(10) %}
                            <tr class="attr-row" data-index="{{ i }}">
                                <td class="attr-type-cell text-center">
                                    <span class="badge bg-primary attr-type-badge">모집단</span>
                                </td>
                                <td><strong>attribute{{ i }}</strong></td>
                                <td>
                                    <input type="text"
                                           class="form-control form-control-sm attribute-input"
                                           id="attr-input-{{ i }}"
                                           placeholder="예: 계정ID, 검토일자, 승인자 등"
                                           maxlength="100">
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" style="width: 100px; height: 38px;">닫기</button>
                    <button type="button" class="btn btn-primary" onclick="saveAttributes()" style="width: 100px; height: 38px;">저장</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 기준통제 추가 모달 -->
    <div class="modal fade" id="addModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">새 기준통제 추가</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form id="addForm">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">통제코드 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="add-control-code" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">통제명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="add-control-name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">카테고리 <span class="text-danger">*</span></label>
                            <select class="form-select" id="add-control-category" required>
                                <option value="">선택하세요</option>
                                <option value="APD">APD</option>
                                <option value="PC">PC</option>
                                <option value="CO">CO</option>
                                <option value="PD">PD</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">설명</label>
                            <textarea class="form-control" id="add-control-description" rows="4"></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" style="width: 100px; height: 38px;">닫기</button>
                        <button type="submit" class="btn btn-primary" style="width: 100px; height: 38px;">추가</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- 기준통제 수정 모달 -->
    <div class="modal fade" id="editModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">기준통제 수정</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form id="editForm">
                    <div class="modal-body">
                        <input type="hidden" id="edit-std-control-id">
                        <div class="mb-3">
                            <label class="form-label">통제코드 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="edit-control-code" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">통제명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="edit-control-name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">카테고리 <span class="text-danger">*</span></label>
                            <select class="form-select" id="edit-control-category" required>
                                <option value="APD">APD</option>
                                <option value="PC">PC</option>
                                <option value="CO">CO</option>
                                <option value="PD">PD</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">설명</label>
                            <textarea class="form-control" id="edit-control-description" rows="4"></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" style="width: 100px; height: 38px;">닫기</button>
                        <button type="submit" class="btn btn-warning" style="width: 100px; height: 38px;">수정</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- 토스트 메시지 컨테이너 -->
    <div class="toast-container">
        <div id="successToast" class="toast align-items-center text-bg-success border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="fas fa-check-circle me-2"></i>
                    <span id="toastMessage"></span>
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        let currentStdControlId = null;
        let attributeModalInstance = null;
        let addModalInstance = null;
        let editModalInstance = null;
        let toastInstance = null;

        // 토스트 메시지 표시 함수
        function showToast(message) {
            const toastEl = document.getElementById('successToast');
            const messageEl = document.getElementById('toastMessage');
            messageEl.textContent = message;

            // 매번 새로운 인스턴스 생성 (delay 적용을 위해)
            toastInstance = new bootstrap.Toast(toastEl, {
                autohide: true,
                delay: 2500
            });

            toastInstance.show();
        }

        document.addEventListener('DOMContentLoaded', function() {
            // 모달 인스턴스 초기화
            const modalEl = document.getElementById('attributeModal');
            attributeModalInstance = new bootstrap.Modal(modalEl);

            const addModalEl = document.getElementById('addModal');
            addModalInstance = new bootstrap.Modal(addModalEl);

            const editModalEl = document.getElementById('editModal');
            editModalInstance = new bootstrap.Modal(editModalEl);

            // 추가 폼 제출
            document.getElementById('addForm').addEventListener('submit', handleAddSubmit);

            // 수정 폼 제출
            document.getElementById('editForm').addEventListener('submit', handleEditSubmit);

            // 모집단 attribute 개수 변경 시 배지 업데이트
            const popCountInput = document.getElementById('population-attr-count');
            if (popCountInput) {
                popCountInput.addEventListener('input', updateAttributeTypeBadges);
            }
        });

        // Attribute 타입 배지 업데이트
        function updateAttributeTypeBadges() {
            const popCount = parseInt(document.getElementById('population-attr-count').value) || 0;
            const rows = document.querySelectorAll('.attr-row');

            rows.forEach((row, index) => {
                const badge = row.querySelector('.attr-type-badge');
                if (index < popCount) {
                    badge.textContent = '모집단';
                    badge.className = 'badge bg-primary attr-type-badge';
                } else {
                    badge.textContent = '증빙';
                    badge.className = 'badge bg-success attr-type-badge';
                }
            });
        }

        // Attribute 모달 열기
        function openAttributeModal(stdControlId, controlCode, controlName) {
            currentStdControlId = stdControlId;

            // 모달 정보 표시
            document.getElementById('modal-control-code').textContent = controlCode;
            document.getElementById('modal-control-name').textContent = controlName;

            // 기존 attribute 값 로드
            loadAttributes(stdControlId);

            // 모달 표시
            attributeModalInstance.show();
        }

        // 기존 attribute 값 로드
        function loadAttributes(stdControlId) {
            fetch(`/admin/api/standard-control/${stdControlId}/attributes`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const attributes = data.attributes;

                        // attribute 필드 로드
                        for (let i = 0; i < 10; i++) {
                            const input = document.getElementById(`attr-input-${i}`);
                            input.value = attributes[`attribute${i}`] || '';
                        }

                        // population_attribute_count 로드
                        const popCountInput = document.getElementById('population-attr-count');
                        popCountInput.value = data.population_attribute_count !== undefined ? data.population_attribute_count : 2;

                        // 배지 업데이트
                        updateAttributeTypeBadges();
                    } else {
                        alert('로드 실패: ' + (data.message || '알 수 없는 오류'));
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Attribute 로드 중 오류가 발생했습니다.');
                });
        }

        // Attribute 저장
        function saveAttributes() {
            if (!currentStdControlId) {
                alert('오류: 기준통제 ID가 없습니다.');
                return;
            }

            // attribute 값 수집
            const attributes = {};
            for (let i = 0; i < 10; i++) {
                const input = document.getElementById(`attr-input-${i}`);
                if (input && input.value.trim()) {
                    attributes[`attribute${i}`] = input.value.trim();
                }
            }

            // population_attribute_count 수집
            const popCountInput = document.getElementById('population-attr-count');
            let populationAttributeCount = parseInt(popCountInput.value);

            if (isNaN(populationAttributeCount) || populationAttributeCount < 0) {
                populationAttributeCount = 2;
            }

            console.log('[saveAttributes] populationAttributeCount:', populationAttributeCount);

            // 서버에 저장
            fetch(`/admin/api/standard-control/${currentStdControlId}/attributes`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    attributes,
                    population_attribute_count: populationAttributeCount
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // 모달 닫기
                    if (attributeModalInstance) {
                        attributeModalInstance.hide();
                    }

                    // 토스트 메시지 표시
                    showToast('Attribute 설정이 저장되었습니다.');

                    // 페이지 새로고침 (배지 업데이트) - 토스트가 보이도록 딜레이
                    setTimeout(() => location.reload(), 2500);
                } else {
                    alert('저장 실패: ' + (data.message || '알 수 없는 오류'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('저장 중 오류가 발생했습니다.');
            });
        }

        // 수정 모달 열기 (data 속성에서 읽기)
        function openEditModalFromData(button) {
            const stdControlId = button.getAttribute('data-id');
            const controlCode = button.getAttribute('data-code');
            const controlName = button.getAttribute('data-name');
            const controlCategory = button.getAttribute('data-category');
            const controlDescription = button.getAttribute('data-description');

            document.getElementById('edit-std-control-id').value = stdControlId;
            document.getElementById('edit-control-code').value = controlCode;
            document.getElementById('edit-control-name').value = controlName;
            document.getElementById('edit-control-category').value = controlCategory;
            document.getElementById('edit-control-description').value = controlDescription;

            editModalInstance.show();
        }

        // 수정 폼 제출 처리
        function handleEditSubmit(e) {
            e.preventDefault();

            const stdControlId = document.getElementById('edit-std-control-id').value;
            const controlCode = document.getElementById('edit-control-code').value;
            const controlName = document.getElementById('edit-control-name').value;
            const controlCategory = document.getElementById('edit-control-category').value;
            const controlDescription = document.getElementById('edit-control-description').value;

            fetch(`/admin/api/standard-control/${stdControlId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    control_code: controlCode,
                    control_name: controlName,
                    control_category: controlCategory,
                    control_description: controlDescription
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    editModalInstance.hide();
                    showToast('기준통제가 수정되었습니다.');
                    setTimeout(() => location.reload(), 2500);
                } else {
                    alert('수정 실패: ' + (data.message || '알 수 없는 오류'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('수정 중 오류가 발생했습니다.');
            });
        }

        // 추가 모달 열기
        function openAddModal() {
            // 폼 초기화
            document.getElementById('add-control-code').value = '';
            document.getElementById('add-control-name').value = '';
            document.getElementById('add-control-category').value = '';
            document.getElementById('add-control-description').value = '';

            addModalInstance.show();
        }

        // 추가 폼 제출 처리
        function handleAddSubmit(e) {
            e.preventDefault();

            const controlCode = document.getElementById('add-control-code').value;
            const controlName = document.getElementById('add-control-name').value;
            const controlCategory = document.getElementById('add-control-category').value;
            const controlDescription = document.getElementById('add-control-description').value;

            fetch('/admin/api/standard-control', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    control_code: controlCode,
                    control_name: controlName,
                    control_category: controlCategory,
                    control_description: controlDescription
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    addModalInstance.hide();
                    showToast('기준통제가 추가되었습니다.');
                    setTimeout(() => location.reload(), 2500);
                } else {
                    alert('추가 실패: ' + (data.message || '알 수 없는 오류'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('추가 중 오류가 발생했습니다.');
            });
        }

        // 삭제 함수
        function deleteControl(stdControlId, controlCode) {
            if (!confirm(`'${controlCode}' 기준통제를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.`)) {
                return;
            }

            fetch(`/admin/api/standard-control/${stdControlId}`, {
                method: 'DELETE'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast('기준통제가 삭제되었습니다.');
                    setTimeout(() => location.reload(), 2500);
                } else {
                    alert('삭제 실패: ' + (data.message || '알 수 없는 오류'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('삭제 중 오류가 발생했습니다.');
            });
        }
    </script>
</body>
</html>
