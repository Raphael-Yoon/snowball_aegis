<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - 사용자 관리</title>
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

    <div class="container mt-4">
        <!-- 플래시 메시지 -->
        {% with messages = get_flashed_messages() %}
            {% if messages %}
                {% for message in messages %}
                    <div class="alert alert-info alert-dismissible fade show" role="alert">
                        {{ message }}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1><i class="fas fa-users me-2"></i>사용자 관리</h1>
            <div>
                <a href="/admin" class="btn btn-outline-secondary me-2">
                    <i class="fas fa-arrow-left me-1"></i>관리자 대시보드
                </a>
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUserModal">
                    <i class="fas fa-plus me-1"></i>새 사용자 추가
                </button>
            </div>
        </div>

        <!-- 사용자 목록 테이블 -->
        <div class="card">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>회사명</th>
                                <th>사용자명</th>
                                <th>이메일</th>
                                <th>연락처</th>
                                <th>관리자</th>
                                <th>활성화 기간</th>
                                <th>마지막 로그인</th>
                                <th>작업</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for user in users %}
                            <tr>
                                <td>{{ user.company_name or '-' }}</td>
                                <td>{{ user.user_name }}</td>
                                <td>{{ user.user_email }}</td>
                                <td>{{ user.phone_number or '-' }}</td>
                                <td>
                                    {% if user.admin_flag == 'Y' %}
                                        <span class="badge bg-danger">관리자</span>
                                    {% else %}
                                        <span class="badge bg-secondary">일반</span>
                                    {% endif %}
                                </td>
                                <td>
                                    <small>
                                        {{ user.effective_start_date[:10] if user.effective_start_date else '-' }} ~ 
                                        {{ user.effective_end_date[:10] if user.effective_end_date else '무제한' }}
                                    </small>
                                </td>
                                <td>
                                    <small>{{ user.last_login_date[:16] if user.last_login_date else '없음' }}</small>
                                </td>
                                <td>
                                    <button type="button" class="btn btn-sm btn-outline-warning" 
                                            onclick="switchUser({{ user.user_id }}, '{{ user.user_name }}')" 
                                            title="이 사용자로 스위치">
                                        <i class="fas fa-user-secret"></i>
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-primary" 
                                            onclick="editUser({{ user.user_id }}, '{{ user.company_name or '' }}', '{{ user.user_name }}', '{{ user.user_email }}', '{{ user.phone_number or '' }}', '{{ user.admin_flag }}', '{{ user.effective_start_date[:10] if user.effective_start_date else '' }}', '{{ user.effective_end_date[:10] if user.effective_end_date else '' }}')" 
                                            data-bs-toggle="modal" data-bs-target="#editUserModal">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-success" 
                                            onclick="extendUser({{ user.user_id }}, '{{ user.user_name }}')" 
                                            data-bs-toggle="modal" data-bs-target="#extendUserModal"
                                            title="1년 연장">
                                        <i class="fas fa-calendar-plus"></i>
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-danger" 
                                            onclick="deleteUser({{ user.user_id }}, '{{ user.user_name }}')" 
                                            data-bs-toggle="modal" data-bs-target="#deleteUserModal">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
                
                {% if not users %}
                <div class="text-center py-4">
                    <i class="fas fa-users fa-3x text-muted mb-3"></i>
                    <p class="text-muted">등록된 사용자가 없습니다.</p>
                </div>
                {% endif %}
            </div>
        </div>
    </div>

    <!-- 사용자 추가 모달 -->
    <div class="modal fade" id="addUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">새 사용자 추가</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form action="/admin/users/add" method="post">
                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">회사명</label>
                            <input type="text" class="form-control" name="company_name">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">사용자명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="user_name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">이메일 <span class="text-danger">*</span></label>
                            <input type="email" class="form-control" name="user_email" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">연락처</label>
                            <input type="tel" class="form-control" name="phone_number">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">관리자 권한</label>
                            <select class="form-select" name="admin_flag">
                                <option value="N">일반 사용자</option>
                                <option value="Y">관리자</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">활성화 시작일</label>
                            <input type="date" class="form-control" name="effective_start_date" value="{{ today }}">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">활성화 종료일 <small class="text-muted">(비어있으면 무제한)</small></label>
                            <input type="date" class="form-control" name="effective_end_date">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">취소</button>
                        <button type="submit" class="btn btn-sm btn-primary">추가</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- 사용자 수정 모달 -->
    <div class="modal fade" id="editUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">사용자 정보 수정</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form id="editUserForm" method="post">
                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">회사명</label>
                            <input type="text" class="form-control" name="company_name" id="edit_company_name">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">사용자명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="user_name" id="edit_user_name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">이메일 <span class="text-danger">*</span></label>
                            <input type="email" class="form-control" name="user_email" id="edit_user_email" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">연락처</label>
                            <input type="tel" class="form-control" name="phone_number" id="edit_phone_number">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">관리자 권한</label>
                            <select class="form-select" name="admin_flag" id="edit_admin_flag">
                                <option value="N">일반 사용자</option>
                                <option value="Y">관리자</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">활성화 시작일</label>
                            <input type="date" class="form-control" name="effective_start_date" id="edit_effective_start_date">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">활성화 종료일 <small class="text-muted">(비어있으면 무제한)</small></label>
                            <input type="date" class="form-control" name="effective_end_date" id="edit_effective_end_date">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" style="width: 100px;">닫기</button>
                        <button type="submit" class="btn btn-primary" style="width: 100px;">수정</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- 사용자 1년 연장 확인 모달 -->
    <div class="modal fade" id="extendUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title text-success">사용자 기간 연장</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p><strong id="extendUserName"></strong> 사용자의 사용 기간을 1년 연장하시겠습니까?</p>
                    <ul class="list-unstyled">
                        <li><i class="fas fa-calendar-day text-primary me-2"></i>활성화 시작일: <strong>오늘</strong></li>
                        <li><i class="fas fa-calendar-plus text-success me-2"></i>활성화 종료일: <strong>1년 후</strong></li>
                    </ul>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">취소</button>
                    <form id="extendUserForm" method="post" style="display:inline;">
                        <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                        <button type="submit" class="btn btn-sm btn-success">1년 연장</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- 사용자 삭제 확인 모달 -->
    <div class="modal fade" id="deleteUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title text-danger">사용자 삭제 확인</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p><strong id="deleteUserName"></strong> 사용자를 정말 삭제하시겠습니까?</p>
                    <p class="text-danger"><small>이 작업은 되돌릴 수 없습니다.</small></p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">취소</button>
                    <form id="deleteUserForm" method="post" style="display:inline;">
                        <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                        <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editUser(userId, companyName, userName, userEmail, phoneNumber, adminFlag, startDate, endDate) {
            document.getElementById('editUserForm').action = '/admin/users/edit/' + userId;
            document.getElementById('edit_company_name').value = companyName;
            document.getElementById('edit_user_name').value = userName;
            document.getElementById('edit_user_email').value = userEmail;
            document.getElementById('edit_phone_number').value = phoneNumber;
            document.getElementById('edit_admin_flag').value = adminFlag;
            document.getElementById('edit_effective_start_date').value = startDate;
            document.getElementById('edit_effective_end_date').value = endDate;
        }

        function extendUser(userId, userName) {
            document.getElementById('extendUserName').textContent = userName;
            document.getElementById('extendUserForm').action = '/admin/users/extend/' + userId;
        }

        function deleteUser(userId, userName) {
            document.getElementById('deleteUserName').textContent = userName;
            document.getElementById('deleteUserForm').action = '/admin/users/delete/' + userId;
        }

        function switchUser(userId, userName) {
            if (!confirm(`${userName} 사용자로 스위치하시겠습니까?\n\n스위치 후에는 해당 사용자의 권한으로 시스템을 이용하게 됩니다.\n관리자 권한으로 돌아오려면 우측 상단의 "관리자로 돌아가기" 버튼을 클릭하세요.`)) {
                return;
            }
            
            const formData = new FormData();
            formData.append('target_user_id', userId);
            
            fetch('/admin/switch_user', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(`[USER-001] ${userName} 사용자로 스위치되었습니다.`);
                    window.location.href = '/';  // 메인 페이지로 이동
                } else {
                    alert('[USER-002] 스위치 실패: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('[USER-003] 사용자 스위치 중 오류가 발생했습니다.');
            });
        }

        // 오늘 날짜를 기본값으로 설정
        document.addEventListener('DOMContentLoaded', function() {
            const today = new Date().toISOString().split('T')[0];
            const startDateInputs = document.querySelectorAll('input[name="effective_start_date"]');
            startDateInputs.forEach(input => {
                if (!input.value) {
                    input.value = today;
                }
            });
        });
    </script>
</body>
</html>