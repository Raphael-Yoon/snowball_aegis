{% include 'navi.jsp' %}
<div style="padding-top: 70px;">
<div class="container-fluid px-4 py-4">

  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h4 class="fw-bold mb-1"><i class="fas fa-server text-primary me-2"></i>시스템 관리</h4>
      <small class="text-muted">모니터링 대상 시스템을 등록하고 관리합니다.</small>
    </div>
    <button class="btn btn-primary btn-sm" onclick="openAddModal()">
      <i class="fas fa-plus me-1"></i>시스템 등록
    </button>
  </div>

  <div class="card shadow-sm border-0">
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0 align-middle">
          <thead class="table-light">
            <tr>
              <th class="ps-3">코드</th>
              <th>시스템명</th>
              <th>DB 타입</th>
              <th>DB 경로/호스트</th>
              <th>설명</th>
              <th class="text-center">커넥터</th>
              <th class="text-center">상태</th>
              <th class="text-center">연결 테스트</th>
              <th class="text-center">관리</th>
            </tr>
          </thead>
          <tbody id="systemsTableBody">
            {% for s in systems %}
            <tr id="row-{{ s.system_id }}">
              <td class="ps-3 fw-semibold text-primary">{{ s.system_code }}</td>
              <td>{{ s.system_name }}</td>
              <td><span class="badge bg-light text-dark border">{{ s.db_type }}</span></td>
              <td class="text-muted small">{{ s.db_path or s.db_host or '-' }}</td>
              <td class="text-muted small">{{ s.description or '-' }}</td>
              <td class="text-center">
                {% if s.has_connector %}
                <span class="badge bg-success"
                      title="{{ s.connector_name }}&#10;구현 통제: {{ s.implemented_controls | join(', ') }}">
                  <i class="fas fa-check-circle me-1"></i>완료
                </span>
                <div class="text-muted" style="font-size:0.72rem; line-height:1.3;">
                  {{ s.implemented_controls | join(', ') }}
                </div>
                {% else %}
                <span class="badge bg-secondary"
                      title="전용 커넥터 미구현. 통제 매핑 시 SQL 쿼리를 직접 설정하거나 커넥터를 개발해야 합니다.">
                  <i class="fas fa-code me-1"></i>미구현
                </span>
                {% endif %}
              </td>
              <td class="text-center">
                {% if s.is_active == 'Y' %}
                <span class="badge bg-success">활성</span>
                {% else %}
                <span class="badge bg-secondary">비활성</span>
                {% endif %}
              </td>
              <td class="text-center">
                <button class="btn btn-outline-info btn-sm" onclick="testConnection({{ s.system_id }}, '{{ s.system_name }}')">
                  <i class="fas fa-plug"></i>
                </button>
              </td>
              <td class="text-center">
                <button class="btn btn-outline-secondary btn-sm me-1" onclick="openEditModal({{ s | tojson | safe }})">
                  <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-outline-danger btn-sm" onclick="deleteSystem({{ s.system_id }}, '{{ s.system_name }}')">
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
            {% else %}
            <tr><td colspan="9" class="text-center text-muted py-4">등록된 시스템이 없습니다.</td></tr>
            {% endfor %}
          </tbody>
        </table>
      </div>
    </div>
  </div>

</div>
</div>

<!-- 시스템 등록/수정 모달 -->
<div class="modal fade" id="systemModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="systemModalTitle"><i class="fas fa-server me-2"></i>시스템 등록</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="editSystemId">
        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label fw-semibold">시스템 코드 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="systemCode" placeholder="예: TRADE" style="text-transform:uppercase;">
          </div>
          <div class="col-md-8">
            <label class="form-label fw-semibold">시스템명 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="systemName" placeholder="예: 트레이딩 시스템">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">설명</label>
            <input type="text" class="form-control" id="systemDesc" placeholder="시스템에 대한 간략한 설명">
          </div>
          <div class="col-md-4">
            <label class="form-label fw-semibold">DB 타입 <span class="text-danger">*</span></label>
            <select class="form-select" id="dbType" onchange="toggleDbFields()">
              <option value="sqlite">SQLite</option>
              <option value="mysql">MySQL</option>
              <option value="mariadb">MariaDB</option>
            </select>
          </div>

          <!-- SQLite 전용 -->
          <div class="col-md-8" id="sqliteFields">
            <label class="form-label fw-semibold">DB 파일 경로</label>
            <input type="text" class="form-control" id="dbPath" placeholder="예: c:/Python/trade/trade.db">
          </div>

          <!-- MySQL/MariaDB 전용 -->
          <div class="col-md-6 d-none" id="mysqlHost">
            <label class="form-label fw-semibold">호스트</label>
            <input type="text" class="form-control" id="dbHost" placeholder="예: localhost">
          </div>
          <div class="col-md-2 d-none" id="mysqlPort">
            <label class="form-label fw-semibold">포트</label>
            <input type="number" class="form-control" id="dbPort" value="3306">
          </div>
          <div class="col-md-4 d-none" id="mysqlDb">
            <label class="form-label fw-semibold">데이터베이스명</label>
            <input type="text" class="form-control" id="dbName">
          </div>
          <div class="col-md-6 d-none" id="mysqlUser">
            <label class="form-label fw-semibold">사용자</label>
            <input type="text" class="form-control" id="dbUser">
          </div>
          <div class="col-md-6 d-none" id="mysqlPw">
            <label class="form-label fw-semibold">비밀번호</label>
            <input type="password" class="form-control" id="dbPassword">
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button class="btn btn-primary" onclick="saveSystem()"><i class="fas fa-save me-1"></i>저장</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const systemModal = new bootstrap.Modal(document.getElementById('systemModal'));

function toggleDbFields() {
    const t = document.getElementById('dbType').value;
    const isMysql = t === 'mysql' || t === 'mariadb';
    document.getElementById('sqliteFields').classList.toggle('d-none', isMysql);
    ['mysqlHost','mysqlPort','mysqlDb','mysqlUser','mysqlPw'].forEach(id =>
        document.getElementById(id).classList.toggle('d-none', !isMysql)
    );
}

function openAddModal() {
    document.getElementById('systemModalTitle').textContent = '시스템 등록';
    document.getElementById('editSystemId').value = '';
    ['systemCode','systemName','systemDesc','dbPath','dbHost','dbName','dbUser','dbPassword'].forEach(id =>
        document.getElementById(id).value = '');
    document.getElementById('dbType').value = 'sqlite';
    document.getElementById('dbPort').value = '3306';
    toggleDbFields();
    systemModal.show();
}

function openEditModal(s) {
    document.getElementById('systemModalTitle').textContent = '시스템 수정';
    document.getElementById('editSystemId').value = s.system_id;
    document.getElementById('systemCode').value = s.system_code;
    document.getElementById('systemName').value = s.system_name;
    document.getElementById('systemDesc').value = s.description || '';
    document.getElementById('dbType').value = s.db_type || 'sqlite';
    document.getElementById('dbPath').value = s.db_path || '';
    document.getElementById('dbHost').value = s.db_host || '';
    document.getElementById('dbPort').value = s.db_port || 3306;
    document.getElementById('dbName').value = s.db_name || '';
    document.getElementById('dbUser').value = s.db_user || '';
    document.getElementById('dbPassword').value = '';
    toggleDbFields();
    systemModal.show();
}

function saveSystem() {
    const systemId = document.getElementById('editSystemId').value;
    const payload = {
        system_code: document.getElementById('systemCode').value.toUpperCase(),
        system_name: document.getElementById('systemName').value,
        description: document.getElementById('systemDesc').value,
        db_type: document.getElementById('dbType').value,
        db_path: document.getElementById('dbPath').value,
        db_host: document.getElementById('dbHost').value,
        db_port: document.getElementById('dbPort').value || null,
        db_name: document.getElementById('dbName').value,
        db_user: document.getElementById('dbUser').value,
        db_password: document.getElementById('dbPassword').value,
        is_active: 'Y',
    };

    const url = systemId ? `/api/aegis/systems/${systemId}` : '/api/aegis/systems';
    const method = systemId ? 'PUT' : 'POST';

    fetch(url, { method, headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload) })
    .then(r => r.json())
    .then(data => {
        alert(data.message);
        if (data.success) { systemModal.hide(); location.reload(); }
    });
}

function deleteSystem(systemId, name) {
    if (!confirm(`'${name}' 시스템을 비활성화하시겠습니까?`)) return;
    fetch(`/api/aegis/systems/${systemId}`, { method: 'DELETE' })
    .then(r => r.json())
    .then(data => { alert(data.message); if (data.success) location.reload(); });
}

function testConnection(systemId, name) {
    const btn = event.target.closest('button');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

    fetch(`/api/aegis/systems/${systemId}/test`, { method: 'POST' })
    .then(r => r.json())
    .then(data => {
        alert(`[${name}] ${data.message}`);
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-plug"></i>';
    });
}
</script>
