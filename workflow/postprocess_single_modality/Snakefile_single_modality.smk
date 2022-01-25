include: "../preprocess_multimodal/Snakefile_preprocess.smk"

rule all_single_modality:
    input:
        expand('results/single_modality/{modality}/seurat/{feature}/integration/integration_RNA.Rds', modality = antibodies_list, feature = features),
        expand('results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered_renamed.Rds',modality = antibodies_list, feature = 'peaks'), # TODO: use 'peaks' as variable
        expand('results/single_modality/{modality}/seurat/{feature}/bigwig/{idents}/', modality = antibodies_list, feature = 'peaks', idents = ['idents_L1','idents_L2','idents_L3','seurat_clusters']), # TODO: use 'peaks' and idents as variable
        expand('results/single_modality/{modality}/seurat/{feature}/markers/{idents}/markers.csv', modality = antibodies_list, feature = 'peaks', idents = ['idents_L1','idents_L2','idents_L3','seurat_clusters']),

rule integrate_with_scRNA:
    input:
        seurat = 'results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered.Rds',
        rna    = '/data/proj/GCB_MB/single-cell-CUT-Tag/nbiotech_paper/analysis/results/Sten_RNA/clustering/01.clustering_20000cells.Rds', # TODO fix path here
        script = workflow_dir + '/scripts/integrate_CT_RNAseq.R'
    output:
        'results/single_modality/{modality}/seurat/{feature}/integration/integration_RNA.Rds'
    shell:
        "Rscript {input.script} -i {input.seurat} -r {input.rna} -o {output}"


rule cluster_final_and_rename:
    input:
        seurat   = 'results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered.Rds',
        notebook =  workflow_dir + '/notebooks/single_modality/{modality}_rename_clusters.Rmd',
    output:
        'results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered_renamed.Rds'
    params:
        report     = os.getcwd() + '/results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered_renamed.html',
        out_prefix = os.getcwd() + '/results/'
    shell:
        "Rscript -e \"rmarkdown::render(input='{input.notebook}',\
                                        output_file = '{params.report}', \
                                        params=list(out_prefix = '{params.out_prefix}',modality = '{wildcards.modality}', feature = '{wildcards.feature}'))\" "


rule export_bw:
    input:
        seurat    = 'results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered_renamed.Rds',
        fragments = 'results/single_modality/{modality}/fragments/fragments.tsv.gz',
        script    = workflow_dir + '/scripts/export_bw.R'
    output:
        bigwig    = directory('results/single_modality/{modality}/seurat/{feature}/bigwig/{idents}/')
    shell:
        "Rscript {input.script}  --input {input.seurat} --fragments {input.fragments} --output_folder {output.bigwig} --idents {wildcards.idents} "

rule find_markers:
    input:
        seurat = 'results/single_modality/{modality}/seurat/{feature}/Seurat_object_clustered_renamed.Rds',
        script = workflow_dir + '/scripts/find_markers.R'
    output:
        markers = 'results/single_modality/{modality}/seurat/{feature}/markers/{idents}/markers.csv',
    shell:
        "Rscript {input.script} -i {input.seurat} -o {output.markers} --idents {wildcards.idents}"