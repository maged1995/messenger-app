def ci_failure_message():
    project = 'project'
    build_number = 120
    job_name = 'job'
    pipeline_link = 'pipeline_link'

    return f'''Project: `{project}`\nPipeline #{build_number} Has Failed at Job `{job_name}`.\nPull Request: {pipeline_link}'''

def ci_success_message():
    project = 'project'
    build_number = 120
    pipeline_link = 'pipeline_link'

    return f'''Project: `{project}`\nPipeline #{build_number} Has Succeeded\nPull Request: {pipeline_link}'''
