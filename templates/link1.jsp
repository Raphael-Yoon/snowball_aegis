<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>Snowball - RCM 생성</title>
		<!-- Favicon -->
		<link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
		<link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
		<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
		<link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
		<link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
		<style>
			.rcm-table-container {
				margin-top: 2rem;
				padding: 1.5rem;
				border-radius: 12px;
				box-shadow: 0 4px 15px rgba(0,0,0,0.1);
			}
			.control-row {
				border-bottom: 1px solid #eee;
				transition: background 0.2s;
			}
			.control-row:hover {
				background-color: #f8f9fa;
			}
			[data-bs-theme="dark"] #simple-mode-notice {
			color: #000 !important;
		}
		[data-bs-theme="dark"] .rcm-table-container {
				background-color: #1c1f26;
				box-shadow: 0 4px 15px rgba(0,0,0,0.4);
			}
			[data-bs-theme="dark"] .control-row {
				border-bottom-color: #3a3f4b;
			}
			[data-bs-theme="dark"] .control-row:hover {
				background-color: #252930;
			}
			.toggle-detail {
				color: #6c757d;
				transition: transform 0.3s ease;
			}
			.toggle-detail:hover {
				color: #0d6efd;
			}
			.toggle-detail[aria-expanded="true"] i {
				transform: rotate(180deg);
			}
			.detail-row {
				background-color: #f8f9fa !important;
			}
			.detail-row td {
				border-top: none !important;
			}
			.mode-badge {
				font-size: 0.75rem;
				padding: 0.25rem 0.5rem;
				border-radius: 4px;
				cursor: pointer;
			}
			.mode-auto { background: #e3f2fd; color: #1976d2; border: 1px solid #bbdefb; }
			.mode-manual { background: #fff3e0; color: #ef6c00; border: 1px solid #ffe0b2; }
			.editable-content {
				width: 100%;
				min-height: 80px;
				border: 1px solid #ddd;
				border-radius: 4px;
				padding: 0.5rem;
				font-size: 0.9rem;
				resize: vertical;
			}
			.readonly-content {
				font-size: 0.9rem;
				color: #444;
				white-space: pre-wrap;
			}
			.sticky-bottom-bar {
				position: fixed;
				bottom: 0;
				left: 0;
				right: 0;
				background: rgba(255,255,255,0.9);
				backdrop-filter: blur(10px);
				padding: 1rem 2rem;
				box-shadow: 0 -4px 10px rgba(0,0,0,0.05);
				z-index: 1000;
				display: flex;
				justify-content: flex-end;
				gap: 1rem;
			}
			/* 클라우드 환경에 따른 제외 통제 스타일 */
			.excluded-control {
				background-color: #f8f9fa !important;
				color: #adb5bd !important;
			}
			.excluded-control .fw-bold { color: #adb5bd !important; }
			.excluded-control select { 
				background-color: #e9ecef !important; 
				color: #adb5bd !important;
				border-color: #dee2e6 !important;
			}
			.cloud-badge {
				font-size: 0.65rem;
				padding: 0.15rem 0.5rem;
				background: #f0f4ff;
				color: #3f51b5;
				border: 1px solid #d1d9ff;
				border-radius: 12px;
				margin-left: 8px;
				display: inline-flex;
				align-items: center;
				white-space: nowrap;
				font-weight: 600;
				letter-spacing: -0.02em;
			}
		</style>
	</head>
	<body class="bg-light" style="padding-bottom: 80px;">
		{% include 'navi.jsp' %}
		
		<div class="container py-5">
			<div class="row justify-content-center">
				<div class="col-lg-10">
					<h2 class="mb-4 text-primary"><i class="fas fa-clipboard-list me-2"></i>RCM 생성</h2>
					
					<!-- 1. Input Section -->
					<div class="card border-0 shadow-sm mb-4">
						<div class="card-header py-3 d-flex justify-content-between align-items-center">
							<h5 class="mb-0"><i class="fas fa-server me-2"></i>대상 시스템 정보</h5>
{% if is_logged_in %}
							<button class="btn btn-sm btn-outline-secondary" id="btn-expert-mode" onclick="toggleExpertMode()">
								<i class="fas fa-cog me-1"></i>전문가 모드
							</button>
							{% else %}
							<button class="btn btn-sm btn-outline-secondary" id="btn-expert-mode" onclick="showExpertModeToast()" title="로그인 후 이용 가능합니다" style="opacity:0.55; cursor:not-allowed;">
								<i class="fas fa-lock me-1"></i>전문가 모드
							</button>
							{% endif %}
						</div>
						<div class="card-body">
							<form id="system-form">
								<!-- 그룹 1: 기본 정보 -->
								<div class="mb-4">
									<h6 class="text-muted mb-3 border-bottom pb-2"><i class="fas fa-info-circle me-2"></i>기본 정보</h6>
									<div class="row">
										<div class="col-md-6 mb-3">
											<label class="form-label fw-bold">시스템 명칭</label>
											<input type="text" class="form-control" id="system_name" name="system_name" required placeholder="예: SAP ERP, 사내 인사시스템">
										</div>
										<div class="col-md-6 mb-3">
											<label class="form-label fw-bold">Cloud 환경</label>
											<select class="form-select" id="cloud_env" name="cloud_env" onchange="handleCloudEnvChange()">
												<option value="None">미사용 (On-Premise)</option>
												<option value="IaaS">IaaS (EC2, GCE 등)</option>
												<option value="PaaS">PaaS (RDS, Managed DB 등)</option>
												<option value="SaaS">SaaS (Salesforce, ERP 등)</option>
											</select>
										</div>
									</div>
									<div class="row">
										<div class="col-md-4 mb-3">
											<label class="form-label fw-bold">시스템 유형</label>
											<select class="form-select" id="system_type" name="system_type" required onchange="handleSystemTypeChange()">
												<option value="In-house">In-house (자체개발)</option>
												<option value="Package">Package (패키지)</option>
											</select>
										</div>
										<div class="col-md-4 mb-3">
											<label class="form-label fw-bold">Application</label>
											<select class="form-select" id="software" name="software" onchange="handleSoftwareChange()">
												<option value="SAP">SAP ERP</option>
												<option value="ORACLE">Oracle ERP</option>
												<option value="DOUZONE">더존 ERP</option>
												<option value="YOUNG">영림원 ERP</option>
												<option value="ETC">기타 / 자체개발</option>
											</select>
											<input type="text" class="form-control mt-1" id="software_custom" name="software_custom"
												placeholder="패키지명 입력 (예: Workday, MS Dynamics)" style="display:none;">
											<small id="sw_modifiable_badge" class="mt-1 d-none"></small>
										</div>
										<div class="col-md-4 mb-3" id="sw_version_group">
											<label class="form-label fw-bold">Version</label>
											<select class="form-select" id="sw_version" name="sw_version">
												<!-- SAP versions (default) -->
												<option value="ECC">ECC 6.0</option>
												<option value="S4HANA">S/4HANA</option>
												<option value="S4CLOUD">S/4HANA Cloud</option>
											</select>
										</div>
									</div>
								</div>

								<!-- 그룹 2: 인프라 (OS/DB) -->
								<div class="mb-4">
									<h6 class="text-muted mb-3 border-bottom pb-2"><i class="fas fa-hdd me-2"></i>인프라</h6>
									<div class="row">
										<div class="col-md-4 mb-3">
											<label class="form-label fw-bold">OS</label>
											<select class="form-select" id="os" name="os" onchange="handleOsChange()">
												<option value="LINUX">Linux</option>
												<option value="WINDOWS">Windows Server</option>
												<option value="UNIX">Unix (AIX/HP-UX/Solaris)</option>
												<option value="ETC">기타 (OS/2, z/OS 등)</option>
												<option value="N/A" hidden>N/A (CSP Managed)</option>
											</select>
										</div>
										<div class="col-md-4 mb-3" id="os_version_group">
											<label class="form-label fw-bold">Linux 배포판</label>
											<select class="form-select" id="os_version" name="os_version">
												<option value="RHEL">RHEL / CentOS / Rocky</option>
												<option value="UBUNTU">Ubuntu / Debian</option>
											</select>
										</div>
										<div class="col-md-4 mb-3">
											<label class="form-label fw-bold">DB</label>
											<select class="form-select" id="db" name="db" onchange="handleDbChange()">
												<option value="ORACLE">Oracle DB</option>
												<option value="TIBERO">Tibero (Tmax)</option>
												<option value="MSSQL">MS-SQL</option>
												<option value="MYSQL">MySQL/MariaDB</option>
												<option value="POSTGRES">PostgreSQL</option>
												<option value="HANA">SAP HANA</option>
												<option value="ETC">기타 (DB2, Sybase 등)</option>
												<option value="N/A" hidden>N/A (CSP Managed)</option>
											</select>
										</div>
									</div>
								</div>

								<!-- 그룹 3: Tool -->
								<div class="mb-2">
									<h6 class="text-muted mb-3 border-bottom pb-2"><i class="fas fa-tools me-2"></i>Tool</h6>
									<div class="row">
										<div class="col-md-3 mb-3">
											<label class="form-label fw-bold">OS 접근제어</label>
											<select class="form-select" id="os_tool" name="os_tool" onchange="handleOsToolChange()">
												<option value="NONE">미사용 (OS 직접 관리)</option>
												<option value="HIWARE">하이웨어 SAC</option>
												<option value="NETAND">넷앤드</option>
												<option value="CYBERARK">CyberArk PAM</option>
												<option value="SECUREGUARD">시큐어가드</option>
												<option value="ETC">기타</option>
											</select>
										</div>
										<div class="col-md-3 mb-3">
											<label class="form-label fw-bold">DB 접근제어</label>
											<select class="form-select" id="db_tool" name="db_tool" onchange="handleDbToolChange()">
												<option value="NONE">미사용 (DB 직접 관리)</option>
												<option value="CHAKRA">Chakra Max (웨어밸리)</option>
												<option value="DBSAFER">DBSafer (피앤피시큐어)</option>
												<option value="PETRA">Petra (신시웨이)</option>
												<option value="GUARDIUM">IBM Guardium</option>
												<option value="ETC">기타</option>
											</select>
										</div>
										<div class="col-md-3 mb-3">
											<label class="form-label fw-bold">배포 Tool</label>
											<select class="form-select" id="deploy_tool" name="deploy_tool" onchange="handleDeployToolChange()">
												<option value="NONE">미사용 (수동 배포)</option>
												<option value="JENKINS">Jenkins</option>
												<option value="GITLAB">GitLab CI/CD</option>
												<option value="AZURE">Azure DevOps</option>
												<option value="AWS">AWS CodePipeline</option>
												<option value="BAMBOO">Atlassian Bamboo</option>
												<option value="ETC">기타</option>
											</select>
										</div>
										<div class="col-md-3 mb-3">
											<label class="form-label fw-bold">배치 스케줄러</label>
											<select class="form-select" id="batch_tool" name="batch_tool" onchange="handleBatchToolChange()">
												<option value="NONE">미사용 (OS Cron/Task)</option>
												<option value="CONTROLM">Control-M (BMC)</option>
												<option value="AUTOSYS">Autosys (Broadcom)</option>
												<option value="TWS">Tivoli Workload Scheduler</option>
												<option value="RUNDECK">Rundeck</option>
												<option value="ETC">기타</option>
											</select>
										</div>
									</div>
								</div>
							</form>
						</div>
					</div>
					
					<!-- 간편 모드 안내 -->
					<div id="simple-mode-notice" class="alert alert-info border-0 shadow-sm mb-4">
						<i class="fas fa-info-circle me-2"></i>통제 항목은 시스템 정보 기반으로 자동 구성됩니다. 세부 설정이 필요하면 <strong>전문가 모드</strong>를 활성화하세요.
					</div>

					<!-- 2. RCM Table Section -->
					<div class="rcm-table-container" id="rcm-section" style="display:none;">
						<div class="d-flex justify-content-between align-items-center mb-3">
							<h5 class="mb-0 fw-bold">ITGC Risk Control Matrix ({{ master_controls|length }}개 통제항목)</h5>
							<button class="btn btn-sm btn-outline-secondary" type="button" id="btn-toggle-all" onclick="toggleAllDetails()">
								<i class="fas fa-chevron-down me-1"></i>전체 펼치기
							</button>
						</div>

						<div class="table-responsive">
							<table class="table table-hover align-middle" id="rcm-table">
								<thead class="table-primary text-center">
									<tr>
										<th style="width: 70px;">ID</th>
										<th style="width: auto;" class="text-start ps-4">통제 항목</th>
										<th style="width: 110px;">구분</th>
										<th style="width: 110px;">주기</th>
										<th style="width: 110px;">성격</th>
									</tr>
								</thead>
								<tbody id="rcm-tbody">
									{% for control in master_controls %}
									<tr class="control-row" data-id="{{ control.id }}">
										<td class="text-center" style="font-size: 0.9rem;">
											<div class="d-flex flex-column align-items-center">
												<span class="fw-bold text-primary">{{ control.id }}</span>
												<button class="btn btn-sm btn-link p-0 mt-1 toggle-detail"
													data-bs-toggle="collapse" data-bs-target="#detail-{{ control.id }}"
													aria-expanded="false" title="상세 보기">
													<i class="fas fa-chevron-down"></i>
												</button>
											</div>
										</td>
										<td class="ps-4">
											<div class="d-flex align-items-center mb-1">
												<span class="fw-bold me-2" id="name-{{ control.id }}" data-original="{{ control.name }}">{{ control.name }}</span>
												<span class="badge bg-secondary-subtle text-secondary" style="font-size: 0.7rem; font-weight: 500;">{{ control.category }}</span>
											</div>
											<div class="text-muted" style="font-size: 0.8rem; line-height: 1.2;">{{ control.objective }}</div>
										</td>
										<td class="px-2">
											<select class="form-select form-select-sm border-light-subtle" id="type-{{ control.id }}" onchange="handleTypeChange('{{ control.id }}')">
												<option value="Auto" {{ 'selected' if control.type == 'Auto' else '' }}>자동</option>
												<option value="Manual" {{ 'selected' if control.type == 'Manual' else '' }}>수동</option>
											</select>
										</td>
										<td class="px-2">
											<select class="form-select form-select-sm border-light-subtle" id="freq-{{ control.id }}"
												onchange="updatePopulationByFrequency('{{ control.id }}')"
												{{ 'disabled' if control.type == 'Auto' else '' }}>
												<option value="연" {{ 'selected' if control.frequency == '연' else '' }}>연</option>
												<option value="분기" {{ 'selected' if control.frequency == '분기' else '' }}>분기</option>
												<option value="월" {{ 'selected' if control.frequency == '월' else '' }}>월</option>
												<option value="주" {{ 'selected' if control.frequency == '주' else '' }}>주</option>
												<option value="일" {{ 'selected' if control.frequency == '일' else '' }}>일</option>
												<option value="수시" {{ 'selected' if control.frequency == '수시' else '' }}>수시</option>
												<option value="기타" {{ 'selected' if control.frequency == '기타' else '' }}>기타</option>
											</select>
										</td>
										<td class="px-2">
											<div class="d-flex align-items-center">
												<select class="form-select form-select-sm border-light-subtle" id="method-{{ control.id }}" {{ 'disabled' if control.type == 'Auto' else '' }}>
													<option value="예방" {{ 'selected' if control.method == '예방' else '' }}>예방</option>
													<option value="적발" {{ 'selected' if control.method == '적발' else '' }}>적발</option>
												</select>
												<!-- Hidden fields for logic -->
												<input type="hidden" id="population-{{ control.id }}">
												<input type="hidden" id="sample-{{ control.id }}">
											</div>
										</td>
									</tr>
									<!-- 상세 정보 행 (접기/펼치기) -->
									<tr class="detail-row collapse" id="detail-{{ control.id }}">
										<td colspan="5" class="bg-light p-3">
											<div class="row">
												<div class="col-md-5">
													<div class="mb-2">
														<span class="badge bg-danger me-1">{{ control.risk_code }}</span>
														<strong>Risk 설명</strong>
													</div>
													<p class="small text-muted mb-0">{{ control.risk_description }}</p>
												</div>
												<div class="col-md-7 border-start">
													<div class="mb-3">
														<div class="d-flex justify-content-between align-items-center mb-2">
															<strong><i class="fas fa-shield-alt me-1"></i>통제 활동</strong>
															<button class="btn btn-sm btn-link text-decoration-none p-0" onclick="copyToClipboard('activity-detail-{{ control.id }}')">
																<i class="far fa-copy me-1"></i>복사
															</button>
														</div>
														<p class="small mb-0 text-dark" id="activity-detail-{{ control.id }}" style="white-space: pre-wrap;">{{ control.control_description }}</p>
													</div>

													<!-- 모집단 / 모집단 완전성 / 표본수 -->
													<div class="pt-3 border-top mb-3">
														<div class="mb-2"><strong><i class="fas fa-database me-1"></i>모집단 정보</strong></div>
														<div class="row small mb-2">
															<div class="col-md-4">
																<span class="text-muted">모집단:</span>
																<span class="fw-bold ms-1" id="population-name-{{ control.id }}">-</span>
															</div>
															<div class="col-md-3" style="white-space: nowrap;">
																<span class="text-muted">모집단 수:</span>
																<span class="fw-bold ms-1" id="population-count-{{ control.id }}">-</span>
															</div>
															<div class="col-md-3" style="white-space: nowrap;">
																<span class="text-muted">표본수:</span>
																<span class="fw-bold ms-1 text-primary" id="sample-count-{{ control.id }}">-</span>
															</div>
															<div class="col-md-2">
																<span class="text-muted">완전성:</span>
																<span class="fw-bold ms-1 text-success" id="completeness-{{ control.id }}">-</span>
															</div>
														</div>
														<!-- 완전성 상세 (테이블명, 쿼리, 메뉴경로 등) -->
														<div class="small text-muted bg-light p-2 border rounded" id="completeness-detail-{{ control.id }}"
															style="white-space: pre-wrap; display: none;"></div>
													</div>

													<div class="pt-3 border-top">
														<div class="d-flex justify-content-between align-items-center mb-2">
															<strong><i class="fas fa-clipboard-check me-1"></i>테스트 절차</strong>
															<button class="btn btn-sm btn-link text-decoration-none p-0" onclick="copyToClipboard('test-proc-detail-{{ control.id }}')">
																<i class="far fa-copy me-1"></i>복사
															</button>
														</div>
														<div class="small text-muted p-2 border rounded" id="test-proc-detail-{{ control.id }}"
															style="white-space: pre-wrap;"
															data-auto="{{ control.test_procedure_auto }}"
															data-manual="{{ control.test_procedure_manual }}">{{ control.test_procedure_auto if control.type == 'Auto' else control.test_procedure_manual }}</div>
													</div>
												</div>
											</div>
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
		
		<!-- Sticky Bottom Bar -->
		<div class="sticky-bottom-bar">
			<button class="btn btn-outline-secondary" onclick="window.location.reload()">
				<i class="fas fa-undo me-1"></i>초기화
			</button>
			<div class="d-flex align-items-center gap-2">
				<input type="email" class="form-control" id="send_email" placeholder="이메일 주소 입력"
					value="{{ user_email }}" style="width: 250px; height: 38px;">
				<button class="btn btn-success px-4" id="btn-export-excel" style="height: 38px;">
					<i class="fas fa-envelope me-1"></i>RCM 메일 발송
				</button>
			</div>
		</div>
		
		<!-- Loading Overlay -->
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
		<script>
			// 클립보드 복사 함수
			function copyToClipboard(elementId) {
				const element = document.getElementById(elementId);
				const text = element.innerText;
				
				navigator.clipboard.writeText(text).then(() => {
					// 성공 시 피드백 (간단한 alert 또는 토스트)
					const toastContainer = document.createElement('div');
					toastContainer.style.position = 'fixed';
					toastContainer.style.bottom = '100px';
					toastContainer.style.left = '50%';
					toastContainer.style.transform = 'translateX(-50%)';
					toastContainer.style.background = 'rgba(0,0,0,0.7)';
					toastContainer.style.color = 'white';
					toastContainer.style.padding = '0.5rem 1rem';
					toastContainer.style.borderRadius = '20px';
					toastContainer.style.zIndex = '3000';
					toastContainer.innerText = '클립보드에 복사되었습니다.';
					
					document.body.appendChild(toastContainer);
					setTimeout(() => toastContainer.remove(), 2000);
				}).catch(err => {
					console.error('Failed to copy: ', err);
				});
			}

			// 전체 펼치기/접기 함수
			let allExpanded = false;
			// 간편/전문가 모드 토글
		let expertMode = false;
		function toggleExpertMode() {
			{% if not is_logged_in %}
			showExpertModeToast();
			return;
			{% endif %}
			expertMode = !expertMode;
			const rcmSection = document.getElementById('rcm-section');
			const notice = document.getElementById('simple-mode-notice');
			const btn = document.getElementById('btn-expert-mode');
			if (expertMode) {
				rcmSection.style.display = 'block';
				notice.style.display = 'none';
				btn.innerHTML = '<i class="fas fa-compress-alt me-1"></i>간편 모드';
				btn.classList.replace('btn-outline-secondary', 'btn-outline-primary');
			} else {
				rcmSection.style.display = 'none';
				notice.style.display = 'block';
				btn.innerHTML = '<i class="fas fa-cog me-1"></i>전문가 모드';
				btn.classList.replace('btn-outline-primary', 'btn-outline-secondary');
			}
		}

		function toggleAllDetails() {
				const detailRows = document.querySelectorAll('.detail-row');
				const toggleButtons = document.querySelectorAll('.toggle-detail');
				const btnToggleAll = document.getElementById('btn-toggle-all');

				if (allExpanded) {
					// 전체 접기
					detailRows.forEach(row => {
						row.classList.remove('show');
					});
					toggleButtons.forEach(btn => {
						btn.setAttribute('aria-expanded', 'false');
					});
					btnToggleAll.innerHTML = '<i class="fas fa-chevron-down me-1"></i>전체 펼치기';
					allExpanded = false;
				} else {
					// 전체 펼치기
					detailRows.forEach(row => {
						row.classList.add('show');
					});
					toggleButtons.forEach(btn => {
						btn.setAttribute('aria-expanded', 'true');
					});
					btnToggleAll.innerHTML = '<i class="fas fa-chevron-up me-1"></i>전체 접기';
					allExpanded = true;
				}
			}

			// CSRF 토큰 설정
			const csrfToken = "{{ csrf_token() }}";
			
			// Application별 소스 수정 가능 여부 매핑
			const SW_MODIFIABLE = {
				'SAP': true,       // ABAP 커스터마이징 가능
				'ORACLE': true,    // PL/SQL 커스터마이징 가능
				'DOUZONE': false,  // 벤더 관리, 소스 수정 불가
				'YOUNG': false,    // 벤더 관리, 소스 수정 불가
				'ETC': null        // In-house면 자체개발, Package면 사용자 입력에 따라 결정
			};

			// 현재 선택된 Application이 수정 가능한지 반환
			function isModifiable() {
				const systemType = document.getElementById('system_type').value;
				if (systemType === 'In-house') return true; // 자체개발은 항상 수정 가능
				const sw = document.getElementById('software').value;
				return SW_MODIFIABLE[sw] !== false; // null이면 true로 처리 (기타 패키지는 수정 가능으로 간주)
			}

			// 시스템 유형 변경 시 핸들러
			function handleSystemTypeChange() {
				const systemType = document.getElementById('system_type').value;
				const softwareSelect = document.getElementById('software');
				const customInput = document.getElementById('software_custom');
				const etcOption = softwareSelect.querySelector('option[value="ETC"]');
				const sapOption = softwareSelect.querySelector('option[value="SAP"]');
				const oracleOption = softwareSelect.querySelector('option[value="ORACLE"]');
				const douzoneOption = softwareSelect.querySelector('option[value="DOUZONE"]');
				const youngOption = softwareSelect.querySelector('option[value="YOUNG"]');

				if (systemType === 'In-house') {
					// 자체개발: ETC만 표시, 커스텀 입력 숨김
					softwareSelect.value = 'ETC';
					softwareSelect.disabled = true;
					customInput.style.display = 'none';
					if (etcOption) { etcOption.style.display = ''; etcOption.textContent = '자체개발 시스템'; }
					if (sapOption) sapOption.style.display = 'none';
					if (oracleOption) oracleOption.style.display = 'none';
					if (douzoneOption) douzoneOption.style.display = 'none';
					if (youngOption) youngOption.style.display = 'none';
				} else {
					// Package: 모든 SW 선택 가능 + 기타 입력
					softwareSelect.disabled = false;
					if (etcOption) { etcOption.style.display = ''; etcOption.textContent = '기타 패키지'; }
					if (sapOption) sapOption.style.display = '';
					if (oracleOption) oracleOption.style.display = '';
					if (douzoneOption) douzoneOption.style.display = '';
					if (youngOption) youngOption.style.display = '';
					// Package 선택 시 기본 Application: SAP
					softwareSelect.value = 'SAP';
				}
				// SW 변경에 따른 버전 갱신 및 커스텀 입력 표시/숨김
				handleSoftwareChange();
			}

			// Cloud 환경 변경 시 핸들러
			function handleCloudEnvChange() {
				const cloudEnv = document.getElementById('cloud_env').value;
				const osSelect = document.getElementById('os');
				const dbSelect = document.getElementById('db');
				const osVersionGroup = document.getElementById('os_version_group');

				if (cloudEnv === 'SaaS') {
					osSelect.value = 'N/A';
					dbSelect.value = 'N/A';
					osSelect.disabled = true;
					dbSelect.disabled = true;
					// OS가 N/A이면 버전도 숨김
					if (osVersionGroup) osVersionGroup.style.display = 'none';
				} else if (cloudEnv === 'PaaS') {
					osSelect.value = 'N/A';
					osSelect.disabled = true;
					dbSelect.disabled = false;
					if (dbSelect.value === 'N/A') dbSelect.value = 'ORACLE';
					// OS가 N/A이면 버전도 숨김
					if (osVersionGroup) osVersionGroup.style.display = 'none';
				} else {
					osSelect.disabled = false;
					dbSelect.disabled = false;
					if (osSelect.value === 'N/A') osSelect.value = 'LINUX';
					if (dbSelect.value === 'N/A') dbSelect.value = 'ORACLE';
					// OS 변경에 따라 버전 표시/숨김 처리
					handleOsChange();
				}

				// 통제 항목 행 비활성화 시각화
				const allRows = document.querySelectorAll('.control-row');
				allRows.forEach(row => {
					const id = row.dataset.id;
					let isExcluded = false;

					// 1. 모든 Cloud 환경에서 데이터센터(CO06)는 CSP 책임
					if (cloudEnv !== 'None' && id === 'CO06') isExcluded = true;

					// 2. SaaS/PaaS에서는 OS 통제(APD09-APD11, PC06) 제외
					if ((cloudEnv === 'SaaS' || cloudEnv === 'PaaS') && 
						(['APD09', 'APD10', 'APD11', 'PC06'].includes(id))) isExcluded = true;

					// 3. SaaS에서는 DB 통제(APD12-APD14, PC07) 및 프로그램 변경 통제(PC01-PC05) 제외
					if (cloudEnv === 'SaaS' && 
						(['APD12', 'APD13', 'APD14', 'PC01', 'PC02', 'PC03', 'PC04', 'PC05', 'PC07'].includes(id))) isExcluded = true;

					const targetContainer = row.cells[1].querySelector('.d-flex');
					const testProcDetail = document.getElementById(`test-proc-detail-${id}`);
					
					if (isExcluded) {
						row.classList.add('excluded-control');
						row.querySelectorAll('select').forEach(s => s.disabled = true);
						
						if (targetContainer && !targetContainer.querySelector('.cloud-badge')) {
							const badge = document.createElement('span');
							badge.className = 'cloud-badge';
							badge.innerHTML = '<i class="fas fa-cloud me-1"></i>CSP Managed';
							targetContainer.appendChild(badge);
						}

						// 테스트 절차를 SOC 리포트용으로 변경
						if (testProcDetail) {
							// 기존값 백업 (최초 1회)
							if (!testProcDetail.dataset.origManual) {
								testProcDetail.dataset.origManual = testProcDetail.dataset.manual;
								testProcDetail.dataset.origAuto = testProcDetail.dataset.auto;
							}
							const cloudMsg = "[CSP Managed] 본 통제는 클라우드 서비스 제공자의 책임 영역에 해당하므로, 당해년도 CSP의 SOC 1/2 Type II 리포트 상의 물리적/환경적 보안 적정성 검토 결과로 갈음함.";
							testProcDetail.textContent = cloudMsg;
							// 엑셀 전송용 데이터셋도 임시 변경
							testProcDetail.dataset.manual = cloudMsg;
							testProcDetail.dataset.auto = cloudMsg;
						}
					} else {
						row.classList.remove('excluded-control');
						if (targetContainer) {
							const badge = targetContainer.querySelector('.cloud-badge');
							if (badge) badge.remove();
						}

						// 백업된 기존 절차 복구
						if (testProcDetail && testProcDetail.dataset.origManual) {
							testProcDetail.dataset.manual = testProcDetail.dataset.origManual;
							testProcDetail.dataset.auto = testProcDetail.dataset.origAuto;
						}

						// 원래 로직(자동/수동)에 따라 활성화 여부 및 텍스트 재결정
						handleTypeChange(id); 
					}
				});
			}

			// SW 버전 옵션 정의
			const SW_VERSION_OPTIONS = {
				'SAP': [
					{value: 'ECC', text: 'ECC 6.0'},
					{value: 'S4HANA', text: 'S/4HANA (On-Premise)'},
					{value: 'S4CLOUD', text: 'S/4HANA Cloud'}
				],
				'ORACLE': [
					{value: 'R12', text: 'E-Business Suite R12'},
					{value: 'FUSION', text: 'Oracle Fusion Cloud'},
					{value: 'JDE', text: 'JD Edwards'}
				],
				'DOUZONE': [
					{value: 'ICUBE', text: 'iCUBE'},
					{value: 'IU', text: 'iU ERP'},
					{value: 'WEHAGO', text: 'WEHAGO (Cloud)'},
					{value: 'AMARANTH', text: 'Amaranth 10'}
				],
				'YOUNG': [
					{value: 'KSYSTEM', text: 'K-System (Standard)'},
					{value: 'KSYSTEMPLUS', text: 'K-System Plus'},
					{value: 'SYSTEVER', text: 'SystemEver (Cloud)'}
				],
				'ETC': [
					{value: 'CUSTOM', text: '자체개발 시스템'},
					{value: 'OTHER', text: '기타 패키지'}
				]
			};


			// SW 변경 시 버전 옵션 갱신
			function handleSoftwareChange() {
				const sw = document.getElementById('software').value;
				const versionSelect = document.getElementById('sw_version');
				const customInput = document.getElementById('software_custom');
				const options = SW_VERSION_OPTIONS[sw] || [];

				versionSelect.innerHTML = '';
				options.forEach(opt => {
					const option = document.createElement('option');
					option.value = opt.value;
					option.textContent = opt.text;
					versionSelect.appendChild(option);
				});

				// SAP, Oracle EBS만 버전 선택 필요 (테이블/쿼리가 다름)
				const systemType = document.getElementById('system_type').value;
				const versionGroup = document.getElementById('sw_version_group');
				const needsVersion = (sw === 'SAP' || sw === 'ORACLE');

				if (systemType === 'In-house') {
					customInput.style.display = 'none';
					versionGroup.style.display = 'none';
				} else if (sw === 'ETC') {
					customInput.style.display = '';
					versionGroup.style.display = 'none';
				} else if (needsVersion) {
					customInput.style.display = 'none';
					versionGroup.style.display = '';
				} else {
					customInput.style.display = 'none';
					versionGroup.style.display = 'none';
				}

				// SAP S/4HANA 선택 시 DB를 HANA로 자동 변경
				if (sw === 'SAP' && versionSelect.value.includes('S4')) {
					const dbSelect = document.getElementById('db');
					if (dbSelect.value !== 'HANA') {
						dbSelect.value = 'HANA';
						handleDbChange();
					}
				}

				// 수정가능 여부 뱃지 업데이트
				updateModifiableBadge();

				refreshAllPopulations();
			}

			// Application 수정가능 여부 뱃지 표시
			function updateModifiableBadge() {
				const badge = document.getElementById('sw_modifiable_badge');
				const systemType = document.getElementById('system_type').value;
				if (systemType === 'In-house') {
					badge.className = 'mt-1 d-none';
					return;
				}
				const modifiable = isModifiable();
				badge.className = 'mt-1 d-inline-block badge ' + (modifiable ? 'bg-primary' : 'bg-warning text-dark');
				badge.textContent = modifiable ? '소스 수정 가능' : '소스 수정 불가 (벤더 관리)';
			}

			// OS 변경 시 배포판 선택 표시/숨김
			function handleOsChange() {
				const os = document.getElementById('os').value;
				const versionGroup = document.getElementById('os_version_group');

				// Linux일 때만 배포판 선택 표시
				if (os === 'LINUX') {
					versionGroup.style.display = '';
				} else {
					versionGroup.style.display = 'none';
				}

				refreshAllPopulations();
			}

			// DB 변경 시 처리
			function handleDbChange() {
				refreshAllPopulations();
			}

			// OS 접근제어 Tool 변경 시 처리
			function handleOsToolChange() {
				const osTool = document.getElementById('os_tool').value;
				console.log('OS Tool changed:', osTool);
				refreshAllPopulations();
			}

			// DB 접근제어 Tool 변경 시 처리
			function handleDbToolChange() {
				const dbTool = document.getElementById('db_tool').value;
				console.log('DB Tool changed:', dbTool);
				refreshAllPopulations();
			}

			// 배포 Tool 변경 시 처리
			function handleDeployToolChange() {
				const deployTool = document.getElementById('deploy_tool').value;
				console.log('Deploy Tool changed:', deployTool);
				refreshAllPopulations();
			}

			// 배치 스케줄러 Tool 변경 시 처리
			function handleBatchToolChange() {
				const batchTool = document.getElementById('batch_tool').value;
				console.log('Batch Tool changed:', batchTool);
				refreshAllPopulations();
			}

			// 기본값 복원
			function resetVersions() {
				document.getElementById('software').value = 'SAP';
				document.getElementById('os').value = 'LINUX';
				document.getElementById('db').value = 'ORACLE';
				handleSoftwareChange();
				handleOsChange();
				handleDbChange();
			}

			// 주기별 모집단 기준
			const FREQUENCY_POPULATION = {
				'연': 1,
				'분기': 4,
				'월': 12,
				'주': 52,
				'일': 250,
				'수시': 0,
				'기타': 0
			};

			// 주기별 모집단명
			const FREQUENCY_POPULATION_NAME = {
				'연': '연간 모니터링 문서',
				'분기': '분기별 모니터링 문서',
				'월': '월별 모니터링 문서',
				'주': '주별 모니터링 문서',
				'일': '일별 모니터링 문서',
				'수시': '수시 발생 건',
				'기타': '-'
			};

			// 주기 변경 시 모집단 자동 설정
			function updatePopulationByFrequency(id) {
				const freqSelect = document.getElementById(`freq-${id}`);
				const populationInput = document.getElementById(`population-${id}`);
				const freq = freqSelect ? freqSelect.value : '수시';
				const popCount = FREQUENCY_POPULATION[freq] || 0;
				populationInput.value = popCount;
				calculateSample(id);

				// 화면에 모집단 정보 표시
				updatePopulationDisplay(id, freq, popCount);
			}

			// 모집단 정보 화면 업데이트
			function updatePopulationDisplay(id, freq, popCount) {
				const typeSelect = document.getElementById(`type-${id}`);
				const isAuto = typeSelect && typeSelect.value === 'Auto';

				const popNameEl = document.getElementById(`population-name-${id}`);
				const popCountEl = document.getElementById(`population-count-${id}`);
				const sampleCountEl = document.getElementById(`sample-count-${id}`);
				const completenessEl = document.getElementById(`completeness-${id}`);
				const completenessDetailEl = document.getElementById(`completeness-detail-${id}`);

				let popName = FREQUENCY_POPULATION_NAME[freq] || '-';
				let completenessText = '';
				let completenessDetail = '';
				const sampleCount = isAuto || freq === '기타' ? 0 : (FREQUENCY_SAMPLE[freq] || 0);

				// 자동통제일 경우 - 시스템별 조회 방법 표시
				if (isAuto) {
					const template = getPopulationTemplate(id);
					if (template) {
						popName = template.population;
						completenessText = '자동통제';
						completenessDetail = template.completeness;
					} else {
						popName = "N/A (자동통제)";
						completenessText = '자동통제';
						completenessDetail = '자동통제이므로 모집단 완전성 확인 대상에서 제외함\n시스템별 확인 방법은 시스템 선택 후 확인';
					}
				}
				// 수시 통제일 경우 템플릿에서 모집단/완전성 가져오기
				else if (freq === '수시') {
					// APD02, APD03 수동 설정 시 예외 처리 (사용자 요청 사항)
					if (!isAuto && id === 'APD02') {
						popName = "부서이동자리스트";
						completenessText = '✓ 확인';
						completenessDetail = "인사시스템 상의 부서이동자 명단과 권한 회수 내역 전수 대사";
					} else if (!isAuto && id === 'APD03') {
						popName = "퇴사자리스트";
						completenessText = '✓ 확인';
						completenessDetail = "인사시스템 상의 퇴사자 명단과 계정 비활성화 내역 전수 대사";
					} else {
						const template = getPopulationTemplate(id);
						if (template) {
							popName = template.population;
							completenessText = '✓ 확인';
							completenessDetail = template.completeness;
						} else {
							completenessText = '확인 필요';
							completenessDetail = '수시 발생 건이므로 모집단 완전성을 별도로 확인해야 함';
						}
					}
				} else if (popCount > 0 && popName !== '-') {
					completenessText = '✓ 확인';
					completenessDetail = `${popName}이므로 ${popCount}건을 완전성 있는 것으로 확인함`;
				} else {
					completenessText = '-';
					completenessDetail = '';
				}

				if (popNameEl) popNameEl.textContent = popName;
				if (popCountEl) popCountEl.textContent = isAuto ? 'N/A' : (popCount > 0 ? `${popCount}건` : (freq === '수시' ? '조회 필요' : '-'));
				if (sampleCountEl) sampleCountEl.textContent = sampleCount === -1 ? '모집단에 따름' : (sampleCount > 0 ? `${sampleCount}건` : 'N/A');

				if (completenessEl) {
					completenessEl.textContent = completenessText;
				}

				// 완전성 상세 표시 (테이블명, 쿼리, 메뉴경로 등)
				if (completenessDetailEl) {
					if (completenessDetail) {
						completenessDetailEl.innerHTML = formatCompletenessDetail(completenessDetail);
						completenessDetailEl.style.display = 'block';
					} else {
						completenessDetailEl.style.display = 'none';
					}
				}

				// Tool 템플릿에서 테스트 절차가 있으면 업데이트
				const template = getPopulationTemplate(id);
				const testProcEl = document.getElementById(`test-proc-detail-${id}`);
				if (testProcEl && template) {
					const procedure = isAuto ?
						(template.test_procedure_auto || testProcEl.dataset.auto) :
						(template.test_procedure_manual || testProcEl.dataset.manual);
					if (procedure) {
						testProcEl.textContent = procedure;
					}
				}
			}

			// 완전성 상세 정보 포맷팅 (쿼리, 메뉴 등 하이라이트)
			function formatCompletenessDetail(text) {
				if (!text) return '';
				// [자동통제 확인방법] 헤더 하이라이트
				let formatted = text.replace(/\[자동통제 확인방법\]/g, '<span class="badge bg-warning text-dark me-1">자동통제 확인방법</span>');
				// [배포판별 Query] 헤더 하이라이트
				formatted = formatted.replace(/\[배포판별 Query\]/g, '<br><span class="badge bg-primary me-1 mt-2">배포판별 Query</span>');
				// [버전별 참고] 헤더 하이라이트
				formatted = formatted.replace(/\[버전별 참고\]/g, '<br><span class="badge bg-info me-1 mt-2">버전별 참고</span>');
				// [Query] 부분 하이라이트
				formatted = formatted.replace(/\[Query\]/g, '<span class="badge bg-primary me-1">Query</span>');
				// [메뉴] 부분 하이라이트
				formatted = formatted.replace(/\[메뉴\]/g, '<span class="badge bg-success me-1">메뉴</span>');
				// SQL 키워드 강조 (SELECT, FROM, WHERE, BETWEEN, AND, OR)
				formatted = formatted.replace(/\b(SELECT|FROM|WHERE|BETWEEN|AND|OR)\b/g, '<span class="text-primary fw-bold">$1</span>');
				// 테이블명 (대문자+언더스코어 패턴) 강조
				formatted = formatted.replace(/\b(TB[A-Z_]+|TBSM_[A-Z_]+|FND_[A-Z_]+)\b/g, '<span class="text-danger fw-bold">$1</span>');
				// T-Code 강조
				formatted = formatted.replace(/T-Code:\s*([A-Z0-9]+)/g, 'T-Code: <span class="badge bg-secondary">$1</span>');
				// 버전명 강조 (• 로 시작하는 라인의 버전명)
				formatted = formatted.replace(/•\s*([\w\-\/\s]+):/g, '• <strong class="text-info">$1</strong>:');
				return formatted;
			}

			// 주기별 표본수 기준 (수시: -1은 모집단에 따라 결정)
			const FREQUENCY_SAMPLE = {
				'연': 1,
				'분기': 2,
				'월': 2,
				'주': 5,
				'일': 20,
				'수시': -1,
				'기타': 0
			};

			// 모집단/완전성 템플릿 (서버에서 로드)
			let populationTemplates = {
				sw: {},
				os: {},
				db: {},
				os_tool: {},
				db_tool: {},
				deploy_tool: {},
				batch_tool: {}
			};

			// 템플릿 로드
			async function loadPopulationTemplates() {
				try {
					const response = await fetch('/api/rcm/population_templates');
					const result = await response.json();
					if (result.success) {
						populationTemplates.sw = result.sw_templates;
						populationTemplates.os = result.os_templates;
						populationTemplates.db = result.db_templates;
						populationTemplates.os_tool = result.os_tool_templates || {};
						populationTemplates.db_tool = result.db_tool_templates || {};
						populationTemplates.deploy_tool = result.deploy_tool_templates || {};
						populationTemplates.batch_tool = result.batch_tool_templates || {};
						console.log('모집단 템플릿 로드 완료 (Tool 템플릿 포함)');
					}
				} catch (error) {
					console.error('템플릿 로드 실패:', error);
				}
			}

			// 통제별 관련 영역 매핑
			const CONTROL_DOMAIN = {
				// SW 관련 통제 (수동)
				'APD01': 'sw', 'APD02': 'sw', 'APD03': 'sw', 'APD07': 'sw',
				'ST03': 'sw',
				'PD01': 'sw', 'PD02': 'sw', 'PD03': 'sw', 'PD04': 'sw', 'CO05': 'sw',
				// SW 관련 통제 (자동)
				'APD04': 'sw', 'APD05': 'sw', 'APD06': 'sw',
				'CO03': 'sw', 'CO04': 'sw',
				'ST01': 'sw', 'ST02': 'sw',
				// OS 관련 통제
				'APD09': 'os', 'APD10': 'os', 'APD11': 'os', 'PC06': 'os',
				// DB 관련 통제
				'APD08': 'db', 'APD12': 'db', 'APD13': 'db', 'APD14': 'db', 'PC07': 'db',
				// 배포 Tool 관련 통제 (프로그램 변경 관리)
				'PC01': 'deploy', 'PC02': 'deploy', 'PC03': 'deploy', 'PC04': 'deploy', 'PC05': 'deploy',
				// 배치 Tool 관련 통제 (Batch Schedule)
				'CO01': 'batch', 'CO02': 'batch'
			};

			// 버전 value → completeness 텍스트 내 버전명 매핑
			// 주의: 포함 관계가 있는 경우(예: S/4HANA vs S/4HANA Cloud) exclude 패턴으로 구분
			const VERSION_LABEL_MAP = {
				// SW - SAP
				'ECC': {labels: ['ECC 6.0', 'ECC'], exclude: []},
				'S4HANA': {labels: ['S/4HANA'], exclude: ['S/4HANA Cloud']},
				'S4CLOUD': {labels: ['S/4HANA Cloud'], exclude: []},
				// SW - ORACLE
				'R12': {labels: ['R12'], exclude: []},
				'FUSION': {labels: ['Fusion Cloud'], exclude: []},
				'JDE': {labels: ['JDE', 'JD Edwards'], exclude: []},
				// SW - DOUZONE
				'ICUBE': {labels: ['iCUBE'], exclude: []},
				'IU': {labels: ['iU', 'iU ERP'], exclude: []},
				'WEHAGO': {labels: ['WEHAGO'], exclude: []},
				'AMARANTH': {labels: ['Amaranth'], exclude: []},
				// SW - YOUNG
				'KSYSTEM': {labels: ['K-System'], exclude: ['K-System Plus']},
				'KSYSTEMPLUS': {labels: ['K-System Plus'], exclude: []},
				'SYSTEVER': {labels: ['SystemEver'], exclude: []},
				// OS - LINUX (RHEL/CentOS/Rocky/Ubuntu/Debian)
				'RHEL': {labels: ['RHEL', 'CentOS', 'Rocky', 'Alma', 'RHEL/CentOS'], exclude: ['Ubuntu', 'Debian']},
				'UBUNTU': {labels: ['Ubuntu', 'Debian', 'Ubuntu/Debian'], exclude: ['RHEL', 'CentOS', 'Rocky']},
				'RHEL7': {labels: ['RHEL 7', 'CentOS 7', 'RHEL/CentOS'], exclude: ['Ubuntu', 'Debian']},
				'RHEL8': {labels: ['RHEL 8', 'CentOS 8', 'Rocky 8', 'Alma 8', 'RHEL/CentOS'], exclude: ['Ubuntu', 'Debian']},
				'RHEL9': {labels: ['RHEL 9', 'Rocky 9', 'Alma 9', 'RHEL/CentOS'], exclude: ['Ubuntu', 'Debian']},
				'U1804': {labels: ['Ubuntu 18.04', 'Debian 10', 'Ubuntu/Debian'], exclude: ['RHEL', 'CentOS', 'Rocky']},
				'U2004': {labels: ['Ubuntu 20.04', 'Debian 11', 'Ubuntu/Debian'], exclude: ['RHEL', 'CentOS', 'Rocky']},
				'U2204': {labels: ['Ubuntu 22.04', 'Debian 12', 'Ubuntu/Debian'], exclude: ['RHEL', 'CentOS', 'Rocky']},
				// OS - WINDOWS
				'W2016': {labels: ['Server 2016'], exclude: []},
				'W2019': {labels: ['Server 2019'], exclude: []},
				'W2022': {labels: ['Server 2022'], exclude: []},
				// OS - UNIX
				'AIX73': {labels: ['AIX 7.3', 'AIX'], exclude: []},
				'AIX72': {labels: ['AIX 7.2', 'AIX'], exclude: []},
				'HPUX': {labels: ['HP-UX'], exclude: []},
				// DB - ORACLE
				'11G': {labels: ['11g'], exclude: []},
				'12C': {labels: ['12c'], exclude: []},
				'19C': {labels: ['19c'], exclude: []},
				'21C': {labels: ['21c'], exclude: []},
				// DB - TIBERO
				'T6': {labels: ['Tibero 6'], exclude: []},
				'T7': {labels: ['Tibero 7'], exclude: []},
				// DB - MSSQL
				'SQL2017': {labels: ['SQL Server 2017'], exclude: []},
				'SQL2019': {labels: ['SQL Server 2019'], exclude: []},
				'SQL2022': {labels: ['SQL Server 2022'], exclude: []},
				// DB - MYSQL
				'MY8': {labels: ['MySQL 8'], exclude: []},
				'MARIA10': {labels: ['MariaDB 10'], exclude: []},
				// DB - POSTGRES
				'PG13': {labels: ['PostgreSQL 13'], exclude: []},
				'PG14': {labels: ['PostgreSQL 14'], exclude: []},
				'PG15': {labels: ['PostgreSQL 15'], exclude: []},
				// DB - HANA
				'HANA2': {labels: ['HANA 2.0', 'HANA 2'], exclude: ['HANA Cloud']},
				'HANACLOUD': {labels: ['HANA Cloud'], exclude: []},
				// N/A
				'NA': {labels: [], exclude: []},
			};

			// completeness 텍스트에서 선택된 버전에 해당하는 정보만 필터링
			function filterCompletenessByVersion(text, domain) {
				if (!text) return text;

				// 현재 선택된 버전 value 가져오기
				let versionValue;
				if (domain === 'sw') {
					versionValue = document.getElementById('sw_version')?.value;
				} else if (domain === 'os') {
					// OS가 LINUX일 때만 배포판(os_version) 필터링 적용
					const osValue = document.getElementById('os')?.value;
					if (osValue === 'LINUX') {
						versionValue = document.getElementById('os_version')?.value;
					} else {
						// WINDOWS, UNIX 등은 버전별 필터링 없이 전체 표시
						return text;
					}
				} else if (domain === 'db') {
					versionValue = null;
				}

				if (!versionValue) return text;

				const mapping = VERSION_LABEL_MAP[versionValue];
				if (!mapping || mapping.labels.length === 0) return text;

				let result = text;

				// [배포판별 Query] 섹션 필터링
				if (result.includes('[배포판별 Query]')) {
					result = filterSection(result, '[배포판별 Query]', mapping);
				}

				// [버전별 참고] 섹션 필터링
				if (result.includes('[버전별 참고]')) {
					result = filterSection(result, '[버전별 참고]', mapping);
				}

				return result;
			}

			// 특정 섹션에서 버전별 라인 필터링
			function filterSection(text, sectionHeader, mapping) {
				const splitIdx = text.indexOf(sectionHeader);
				if (splitIdx === -1) return text;

				const baseText = text.substring(0, splitIdx).trim();
				const afterHeader = text.substring(splitIdx + sectionHeader.length);

				// 다음 섹션 찾기 ([ 로 시작하는 다음 라인)
				const nextSectionMatch = afterHeader.match(/\n\[/);
				let sectionContent, remainingText;
				if (nextSectionMatch) {
					sectionContent = afterHeader.substring(0, nextSectionMatch.index);
					remainingText = afterHeader.substring(nextSectionMatch.index);
				} else {
					sectionContent = afterHeader;
					remainingText = '';
				}

				// • 로 시작하는 라인에서 매칭되는 버전만 필터링
				const lines = sectionContent.split('\n');
				const matchedLines = lines.filter(line => {
					const trimmed = line.trim();
					if (!trimmed.startsWith('•')) return false;

					// exclude 패턴에 해당하면 제외
					if (mapping.exclude && mapping.exclude.length > 0) {
						for (const ex of mapping.exclude) {
							if (trimmed.includes(ex)) return false;
						}
					}

					// labels 중 하나라도 포함되면 매칭
					return mapping.labels.some(label => trimmed.includes(label));
				});

				if (matchedLines.length > 0) {
					return baseText + '\n\n' + sectionHeader + '\n' + matchedLines.join('\n') + remainingText;
				}

				// 매칭되는 라인이 없으면 해당 섹션 제외하고 반환
				return baseText + remainingText;
			}

			// 현재 선택된 시스템 환경에서 템플릿 가져오기
			function getPopulationTemplate(controlId) {
				const domain = CONTROL_DOMAIN[controlId];
				if (!domain) return null;

				const sw = document.getElementById('software').value;
				const os = document.getElementById('os').value;
				const db = document.getElementById('db').value;
				const osTool = document.getElementById('os_tool').value;
				const dbTool = document.getElementById('db_tool').value;
				const deployTool = document.getElementById('deploy_tool').value;
				const batchTool = document.getElementById('batch_tool').value;

				let template = null;

				if (domain === 'sw' && populationTemplates.sw[sw]) {
					template = populationTemplates.sw[sw][controlId];
				} else if (domain === 'os') {
					// OS Tool이 선택된 경우 Tool 템플릿 우선 적용
					if (osTool !== 'NONE' && populationTemplates.os_tool[osTool] && populationTemplates.os_tool[osTool][controlId]) {
						template = populationTemplates.os_tool[osTool][controlId];
						console.log(`OS Tool 템플릿 적용: ${osTool} - ${controlId}`);
					} else if (populationTemplates.os[os]) {
						template = populationTemplates.os[os][controlId];
					}
				} else if (domain === 'db') {
					// DB Tool이 선택된 경우 Tool 템플릿 우선 적용
					if (dbTool !== 'NONE' && populationTemplates.db_tool[dbTool] && populationTemplates.db_tool[dbTool][controlId]) {
						template = populationTemplates.db_tool[dbTool][controlId];
						console.log(`DB Tool 템플릿 적용: ${dbTool} - ${controlId}`);
					} else if (populationTemplates.db[db]) {
						template = populationTemplates.db[db][controlId];
					}
				} else if (domain === 'deploy') {
					// 배포 Tool이 선택된 경우 Tool 템플릿 적용
					if (deployTool !== 'NONE' && populationTemplates.deploy_tool[deployTool] && populationTemplates.deploy_tool[deployTool][controlId]) {
						template = populationTemplates.deploy_tool[deployTool][controlId];
						console.log(`Deploy Tool 템플릿 적용: ${deployTool} - ${controlId}`);
					} else if (populationTemplates.sw[sw]) {
						// Tool 미사용 시 SW 템플릿 사용
						template = populationTemplates.sw[sw][controlId];
					}
				} else if (domain === 'batch') {
					// 배치 Tool이 선택된 경우 Tool 템플릿 적용
					if (batchTool !== 'NONE' && populationTemplates.batch_tool[batchTool] && populationTemplates.batch_tool[batchTool][controlId]) {
						template = populationTemplates.batch_tool[batchTool][controlId];
						console.log(`Batch Tool 템플릿 적용: ${batchTool} - ${controlId}`);
					} else if (populationTemplates.sw[sw]) {
						// Tool 미사용 시 SW 템플릿 사용
						template = populationTemplates.sw[sw][controlId];
					}
				}

				// 버전 필터링 적용
				if (template) {
					let completenessText = filterCompletenessByVersion(template.completeness, domain);

					// Package 시스템의 변경관리(PC01~PC05) 보충 문구 적용
					const systemType = document.getElementById('system_type').value;
					if (systemType === 'Package' && controlId.startsWith('PC0') && ['PC01','PC02','PC03','PC04','PC05'].includes(controlId)) {
						const modifiable = isModifiable();
						if (modifiable) {
							const supplements = {
								'PC01': '\n\n[소스 수정 가능 Package]\n자체 커스터마이징 건과 벤더 패치를 모두 포함하여 변경 이력 확인.',
								'PC02': '\n\n[소스 수정 가능 Package]\n자체 개발 건은 단위/통합 테스트, 벤더 패치는 별도 검증 후 적용.',
								'PC03': '\n\n[소스 수정 가능 Package]\n자체 개발 건과 벤더 패치 모두 이관 승인 프로세스 준수 확인.'
							};
							if (supplements[controlId]) completenessText += supplements[controlId];
						} else {
							const supplements = {
								'PC01': '\n\n[소스 수정 불가 Package]\n프로그램 변경은 벤더 패치/업데이트만 해당. 당기 벤더 패치 적용 이력을 모집단으로 확인.',
								'PC02': '\n\n[소스 수정 불가 Package]\n벤더 패치 적용 전 테스트서버 검증 수행 여부 확인.',
								'PC03': '\n\n[소스 수정 불가 Package]\n벤더 패치 이관 시 승인 프로세스 준수 여부 확인.',
								'PC04': '\n\n[소스 수정 불가 Package]\n운영계 직접 변경 원천 차단. 변경 제한 설정 활성화 확인.',
								'PC05': '\n\n[소스 수정 불가 Package]\n이관 권한은 벤더 엔지니어 또는 지정 관리자로 제한.'
							};
							if (supplements[controlId]) completenessText += supplements[controlId];
						}
					}

					return {
						population: template.population,
						completeness: completenessText,
						test_procedure_manual: template.test_procedure_manual || null,
						test_procedure_auto: template.test_procedure_auto || null
					};
				}
				return template;
			}

			// 시스템 환경 변경 시 모든 통제의 모집단 정보 갱신 (자동통제 + 수시통제)
			function refreshAllPopulations() {
				const rows = document.querySelectorAll('.control-row');
				rows.forEach(row => {
					const id = row.dataset.id;
					const typeSelect = document.getElementById(`type-${id}`);
					const freqSelect = document.getElementById(`freq-${id}`);
					const isAuto = typeSelect && typeSelect.value === 'Auto';
					const freq = freqSelect ? freqSelect.value : '수시';

					// 자동통제이거나 수시 통제인 경우 갱신
					if (isAuto || freq === '수시') {
						const popCount = FREQUENCY_POPULATION[freq] || 0;
						updatePopulationDisplay(id, freq, popCount);
					}
				});
			}

			// 표본 수 계산
			function calculateSample(id) {
				const sampleInput = document.getElementById(`sample-${id}`);
				const typeSelect = document.getElementById(`type-${id}`);
				const freqSelect = document.getElementById(`freq-${id}`);

				const type = typeSelect ? typeSelect.value : 'Manual';
				const freq = freqSelect ? freqSelect.value : '수시';

				// 자동통제이거나 주기가 '기타'인 경우 표본수는 0
				if (type === 'Auto' || freq === '기타') {
					sampleInput.value = 0;
					sampleInput.placeholder = '';
					return;
				}

				// 주기별 고정 표본수 (수시는 모집단에 따라 결정)
				const sampleSize = FREQUENCY_SAMPLE[freq] || 0;
				if (sampleSize === -1) {
					sampleInput.value = '';
					sampleInput.placeholder = '모집단에 따름';
				} else {
					sampleInput.value = sampleSize;
					sampleInput.placeholder = '';
				}
			}

			// 자동/수동 변경 시 핸들러
			function handleTypeChange(id) {
				const typeSelect = document.getElementById(`type-${id}`);
				const freqSelect = document.getElementById(`freq-${id}`);
				const methodSelect = document.getElementById(`method-${id}`);
				const testProcDetail = document.getElementById(`test-proc-detail-${id}`);
				const nameSpan = document.getElementById(`name-${id}`);
				const otherOption = freqSelect.querySelector('option[value="기타"]');

				if (typeSelect.value === 'Auto') {
					// 자동통제일 때 '기타' 옵션을 보이고 선택
					if (otherOption) otherOption.style.display = '';
					freqSelect.value = '기타';
					methodSelect.value = '예방';
					freqSelect.disabled = true;
					methodSelect.disabled = true;
					// 자동 테스트 절차로 변경
					if (testProcDetail) {
						testProcDetail.textContent = testProcDetail.dataset.auto;
					}
					// 원래 통제명 복원
					if (nameSpan && nameSpan.dataset.original) {
						nameSpan.textContent = nameSpan.dataset.original;
					}
				} else {
					// 수동통제일 때 '기타' 옵션을 감춤
					if (otherOption) otherOption.style.display = 'none';
					freqSelect.disabled = false;
					methodSelect.disabled = false;

					// 현재 주기가 '기타'라면 수동통제의 기본값인 '분기'로 변경
					if (freqSelect.value === '기타') {
						freqSelect.value = '분기';
					}

					// 원래 '자동'인 통제만 모니터링으로 변환 (APD03 제외)
					const autoDefaultControls = ['APD05', 'APD06', 'APD08', 'APD10', 'APD11', 'APD13', 'APD14', 'CHG03', 'CHG04', 'OPS02', 'SUP01', 'SUP02'];
					const isAutoDefault = autoDefaultControls.includes(id);

					if (isAutoDefault && nameSpan && nameSpan.dataset.original) {
						const originalName = nameSpan.dataset.original;
						// "~제한", "~설정" 등을 "모니터링"으로 변환
						let monitoringName = originalName;
						if (originalName.includes('제한')) {
							monitoringName = originalName.replace(/제한[됨다]?$/, '모니터링');
						} else if (originalName.includes('설정')) {
							monitoringName = originalName.replace(/설정[됨다]?$/, '모니터링');
						} else if (originalName.includes('분리')) {
							monitoringName = originalName.replace(/분리[됨다]?$/, '모니터링');
						} else {
							monitoringName = originalName + ' 모니터링';
						}
						nameSpan.textContent = monitoringName;
					}

					// 테스트 절차 변경
					if (testProcDetail) {
						if (isAutoDefault) {
							// 원래 자동통제: 모니터링 테스트 절차 적용
							const freq = freqSelect.value;
							const monitoringProcedure = `1. ${freq}별 모니터링 수행 기록 확인\n` +
								`2. 모니터링 담당자 지정 및 승인 여부 확인\n` +
								`3. 점검 결과 보고서 및 후속조치 이행 현황 검토\n` +
								`4. 미준수 사항 발견 시 시정조치 내역 확인`;
							testProcDetail.textContent = monitoringProcedure;
						} else {
							// 원래 수동통제: 기존 수동 테스트 절차 사용
							testProcDetail.textContent = testProcDetail.dataset.manual;
						}
					}
				}
				// 자동/수동 변경 시 모집단 및 표본수 재계산
				updatePopulationByFrequency(id);
			}

			// 페이지 로드 시 상태 초기화
			document.addEventListener('DOMContentLoaded', async function() {
				// 모집단 템플릿 로드
				await loadPopulationTemplates();

				// 시스템 유형 및 SW 상태 초기화
				handleSystemTypeChange();
				// Cloud 환경 초기화
				handleCloudEnvChange();
				// 버전 선택 초기화
				handleSoftwareChange();
				handleOsChange();
				handleDbChange();

				const rows = document.querySelectorAll('.control-row');
				rows.forEach(row => {
					const id = row.dataset.id;
					// 초기 로드 시 자동/수동 로직을 한 번 실행하여 값과 활성화 상태를 맞춤
					handleTypeChange(id);
				});

				// 초기 로드 후 모든 자동통제/수시통제의 모집단 정보 갱신
				refreshAllPopulations();

				// SW/OS 버전 변경 시에도 모집단 정보 갱신
				['sw_version', 'os_version'].forEach(selectId => {
					const selectEl = document.getElementById(selectId);
					if (selectEl) {
						selectEl.addEventListener('change', () => {
							refreshAllPopulations();
							refreshAllProcedures();
						});
					}
				});
			});

			// 모든 절차를 마스터(범용) 값으로 초기화
			function refreshAllProcedures() {
				// AI 분석 결과가 이미 적용된 경우 사용자에게 알림 (선택 사항)
				console.log('시스템 환경 변경으로 인해 기술 절차를 범용 값으로 초기화합니다.');
				
				const rows = document.querySelectorAll('.control-row');
				rows.forEach(row => {
					const id = row.dataset.id;
					const typeSelect = document.getElementById(`type-${id}`);
					const testProcDetail = document.getElementById(`test-proc-detail-${id}`);
					
					if (testProcDetail) {
						// 백업된 오리지널(범용) 데이터로 복구
						const origAuto = testProcDetail.dataset.origAuto || testProcDetail.dataset.auto;
						const origManual = testProcDetail.dataset.origManual || testProcDetail.dataset.manual;
						
						// 현재 타입에 맞춰 표시
						if (typeSelect && typeSelect.value === 'Auto') {
							testProcDetail.textContent = origAuto;
							testProcDetail.dataset.auto = origAuto; // AI 결과 덮어쓰기 방지 (초기화)
						} else {
							testProcDetail.textContent = origManual;
							testProcDetail.dataset.manual = origManual; // AI 결과 덮어쓰기 방지 (초기화)
						}
					}
				});
			}
			
			// RCM 메일 발송 - 화면에서 수정한 값만 전달 (나머지는 서버의 마스터 데이터 사용)
			document.getElementById('btn-export-excel').addEventListener('click', async function() {
				const userEmail = document.getElementById('send_email').value.trim();
				if (!userEmail) {
					alert('이메일 주소를 입력해주세요.');
					document.getElementById('send_email').focus();
					return;
				}

				// 이메일 형식 검증
				const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
				if (!emailRegex.test(userEmail)) {
					alert('올바른 이메일 주소를 입력해주세요.');
					document.getElementById('send_email').focus();
					return;
				}

				if (!confirm(`RCM 파일을 ${userEmail}로 발송하시겠습니까?`)) {
					return;
				}

				const rows = document.querySelectorAll('.control-row');
				const rcm_data = [];

				rows.forEach(row => {
					const id = row.dataset.id;
					const typeSelect = document.getElementById(`type-${id}`);
					const freqSelect = document.getElementById(`freq-${id}`);
					const methodSelect = document.getElementById(`method-${id}`);
					const activityDetail = document.getElementById(`activity-detail-${id}`);
					const testProcDetail = document.getElementById(`test-proc-detail-${id}`);

					if (typeSelect && freqSelect && methodSelect) {
						rcm_data.push({
							id: id,
							type: typeSelect.value === 'Auto' ? '자동' : '수동',
							frequency: freqSelect.value,
							method: methodSelect.value,
							activity: activityDetail ? activityDetail.textContent : '',
							procedure: testProcDetail ? testProcDetail.textContent : ''
						});
					}
				});

				const systemName = document.getElementById('system_name').value || 'ITGC';
				const cloudEnv = document.getElementById('cloud_env').value;
				const softwareKey = document.getElementById('software').value;
				const softwareCustom = document.getElementById('software_custom').value;
				const osType = document.getElementById('os').value;
				const dbType = document.getElementById('db').value;

				const systemType = document.getElementById('system_type').value;

				const payload = {
					user_email: userEmail,
					system_info: {
						system_name: systemName,
						system_type: systemType,
						cloud_env: cloudEnv,
						software: softwareKey === 'ETC' && softwareCustom ? softwareCustom : softwareKey,
						software_key: softwareKey,
						os: osType,
						db: dbType
					},
					rcm_data: rcm_data
				};

				this.disabled = true;
				this.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>발송 중...';

				try {
					const response = await fetch('/api/rcm/export_excel', {
						method: 'POST',
						headers: {
							'Content-Type': 'application/json',
							'X-CSRFToken': csrfToken
						},
						body: JSON.stringify(payload)
					});

					const result = await response.json();
					if (result.success) {
						alert(result.message);
					} else {
						alert("메일 발송 오류: " + (result.message || '알 수 없는 오류'));
					}
				} catch (error) {
					console.error('Mail send error:', error);
					alert("메일 발송 중 오류가 발생했습니다: " + error.message);
				} finally {
					this.disabled = false;
					this.innerHTML = '<i class="fas fa-envelope me-1"></i>RCM 메일 발송';
				}
			});
		</script>

	<!-- 전문가 모드 접근 제한 토스트 -->
	<div class="position-fixed top-0 end-0 p-3" style="margin-top: 60px;" style="z-index: 9999">
		<div id="expertModeToast" class="toast align-items-center text-bg-secondary border-0" role="alert" aria-live="assertive" aria-atomic="true" data-bs-delay="3000">
			<div class="d-flex">
				<div class="toast-body">
					<i class="fas fa-lock me-2"></i>전문가 모드는 로그인 후 이용 가능합니다.
				</div>
				<button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
			</div>
		</div>
	</div>
	<script>
		function showExpertModeToast() {
			const toastEl = document.getElementById('expertModeToast');
			const toast = new bootstrap.Toast(toastEl);
			toast.show();
		}
	</script>
	</body>
</html>
