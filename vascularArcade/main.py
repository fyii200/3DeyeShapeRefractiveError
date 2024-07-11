import os
import argparse
from tqdm import tqdm
import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import multiprocessing
from preprocess import arcade_detector
from arcade_model import parabola_ls, RANSAC

join = os.path.join

homeDir = r"/Users/fabianyii/Library/CloudStorage/OneDrive-UniversityofEdinburgh/Projects/eyeShape"
d = pd.read_csv(join(homeDir,"CSVoutputs", "UKB", "ODfoveaResults.csv"))
names = list(d.fundus)
            
##################### Set arguments #####################  
parser = argparse.ArgumentParser(description = "Vascular Arcade Analysis")
parser.add_argument("--parallelisation",
                    action = "store_true") 
parser.add_argument("--crop_to_fovea", 
                    action = "store_true") 
parser.add_argument("--image_name", 
                    type = str, 
                    default = None) 
parser.add_argument("--vessel_path", 
                    type = str, 
                    default = join(homeDir, "imageOutputs", "UKB", "vesselMasks", "artery_vein", "artery_binary_process")) 
parser.add_argument("--disc_centroid_img_width", 
                    type = int, 
                    default = 2048)
parser.add_argument("--disc_centroid_img_height", 
                    type = int, 
                    default = 1536)
parser.add_argument("--width_after_cropped", 
                    type = int, 
                    default = 450)
parser.add_argument("--pad_width", 
                    type = int, 
                    default = 25)
parser.add_argument("--morph_open_min_trigger_area", 
                    type = int, 
                    default = 1000)
parser.add_argument("--morph_open_min_trigger_num", 
                    type = int, 
                    default = 2)
parser.add_argument("--rect_open_min_angle", 
                    type = int, 
                    default = -40)
parser.add_argument("--rect_open_max_angle", 
                    type = int, 
                    default = 40)
parser.add_argument("--rect_open_num_angles", 
                    type = int, 
                    default = 15)
parser.add_argument("--dist_trans_thres", 
                    type = float, 
                    default = 0.985)
parser.add_argument("--area_open_thres_quantile", 
                    type = float, 
                    default = 0.7)
parser.add_argument("--area_open_thres_cap", 
                    type = int, 
                    default = 300)
parser.add_argument("--hough_min_trial_radius", 
                    type = int, 
                    default = 5)
parser.add_argument("--hough_max_trial_radius", 
                    type = int, 
                    default = 15)
parser.add_argument("--hough_binary_quantile", 
                    type = float, 
                    default = 0.98)
parser.add_argument("--rect_close_min_angle", 
                    type = int, 
                    default = -70)
parser.add_argument("--rect_close_max_angle", 
                    type = int, 
                    default = 70)
parser.add_argument("--rect_close_num_angles", 
                    type = int, 
                    default = 15)
parser.add_argument("--segmented_lr_fit_intercept", 
                    action = "store_true")
parser.add_argument("--show_preprocessing", 
                    action = "store_true")
parser.add_argument("--show_ransac_parabola", 
                    action = "store_true")
parser.add_argument("--save_fig", 
                    action = "store_true")
parser.add_argument("--show_ransac_lin", 
                    action = "store_true")
parser.add_argument("--show_ls_parabola", 
                    action = "store_true")
parser.add_argument("--mark_vertex", 
                    action = "store_true")
parser.add_argument("--fit_verbose", 
                    action = "store_true")
args = parser.parse_args()

            
def build_pipeline(name):
    ################ Pre-processing ################
    ## Original full-sized mask (912x912)
    vessel = arcade_detector(name, args.vessel_path)
    original_mask = vessel.mask
    # Crop the mask around the optic disc
    resize_ratio_width = vessel.size()[1] / args.disc_centroid_img_width
    resize_ratio_height = vessel.size()[0] / args.disc_centroid_img_height
    disc_x = list(d[d.fundus == name].ODx)[0] * resize_ratio_width
    disc_y = list(d[d.fundus == name].ODy)[0] * resize_ratio_height
    if args.crop_to_fovea:
        fovea_x = list(d[d.fundus==name].foveaX)[0] * resize_ratio_width
        fovea_y = list(d[d.fundus==name].foveaY)[0] * resize_ratio_height
        vessel.crop_to_fovea(disc_x, disc_y, fovea_x, fovea_y, disc_nasal_width=50)
    else:
        vessel.crop_around_disc(disc_x, disc_y, args.width_after_cropped)
    mask_cropped = vessel.mask
    
    ## If cropped mask is not empty
    if len(np.unique(mask_cropped)) > 1: 
        # Pad mask
        vessel.pad(args.pad_width)
        
        # Remove small vessels by distance transform
        vessel.dist_transform(args.morph_open_min_trigger_area,
                              args.morph_open_min_trigger_num,
                              args.dist_trans_thres)
        dist_trans_mask = vessel.mask
    
        # Further remove small vessels by morphological area opening
        vessel.area_opening(args.morph_open_min_trigger_area, 
                            args.morph_open_min_trigger_num, 
                            args.area_open_thres_quantile, 
                            args.area_open_thres_cap, 
                            connectivity=1)
        area_opened_mask = vessel.mask
    
        # Detect parabola via circle Hough transform
        vessel.detect_parabola(args.hough_min_trial_radius, 
                               args.hough_max_trial_radius, 
                               args.hough_binary_quantile)
        raw_parabola_mask = vessel.mask
    
        # Remove small vessels by morphological area opening
        vessel.area_opening(args.morph_open_min_trigger_area, 
                            args.morph_open_min_trigger_num, 
                            args.area_open_thres_quantile, 
                            args.area_open_thres_cap)
        parabola_mask_opened = vessel.mask
    
        # Image reconstruction via morphological closing using a rectangular kernel rotated between -70 & 70
        vessel.rectangular_closing(args.rect_close_min_angle, 
                                   args.rect_close_max_angle, 
                                   args.rect_close_num_angles)
        parabola_mask_closed = vessel.mask
    
        # Skeletonize the mask
        vessel.skeleton()
        skeletonised_mask = vessel.mask
        
        ## Display mask at each preprocessing step ##
        if args.show_preprocessing:              
            fig, p = plt.subplots(2, 4, figsize=(9, 8))
            p[0,0].imshow(mask_cropped, cmap='gray'); p[0,0].axis("off")
            p[0,1].imshow(dist_trans_mask, cmap='gray'); p[0,1].axis("off")
            p[0,2].imshow(area_opened_mask, cmap='gray'); p[0,2].axis("off")
            p[0,3].imshow(raw_parabola_mask, cmap='gray'); p[0,3].axis("off")
            p[1,0].imshow(parabola_mask_opened, cmap='gray'); p[1,0].axis("off")
            p[1,1].imshow(parabola_mask_closed, cmap='gray'); p[1,1].axis("off")
            p[1,2].imshow(skeletonised_mask, cmap='gray'); p[1,2].axis("off")
            plt.subplots_adjust(wspace=0, hspace=0.01)
            
        ################ Model fitting ################
        ## RANSAC parabola
        ransac = RANSAC(vessel.mask)
        ransac.fit_parabola()
        conc_rp, med_residual_rp, top_med_residual_rp, bottom_med_residual_rp, r2_rp = ransac.compute_metrics(model="parabola", verbose=args.fit_verbose)
        if args.show_ransac_parabola:
            ransac.display_parabola(args.mark_vertex)      
        
        ## Least square parabola
        if args.show_ls_parabola:
            parabola = parabola_ls(vessel.mask)
            parabola.fit()
            conc_lsp, med_residual_lsp, r2_lsp = parabola.compute_metrics(verbose=args.fit_verbose)
            parabola.display_fit(args.mark_vertex)
            
        ## Segmented linear model
        if args.show_ransac_lin:
            ransac.fit_segmented_lr(args.segmented_lr_fit_intercept)
            # Compute standard metrics
            med_residual_lin, r2_lin = ransac.compute_metrics(model="linear", verbose=args.fit_verbose)
            # compute parabolic index
            med_residual_ratio, r2_ratio = ransac.parabola_index() 
            ransac.display_segmented_lr() 
        
        # Save figure?
        if args.save_fig:
            if os.path.normpath(args.vessel_path).split(os.sep)[-1] == "artery_binary_process":
                    save_dir = join(homeDir, "imageOutputs", "PREVENT", "vesselArcades", "ransac_artery")
            else:
                save_dir = join(homeDir,"imageOutputs", "PREVENT", "vesselArcades", "ransac_vein")
            os.makedirs(save_dir) if not os.path.exists(save_dir) else None  
            plt.savefig(join(save_dir, name.split(".")[0] + ".png"), bbox_inches="tight") 
            plt.close()
        
        # Return metrics
        if args.show_ransac_lin:
            return name, conc_rp, med_residual_rp, top_med_residual_rp, bottom_med_residual_rp, r2_rp, med_residual_lin, r2_lin, med_residual_ratio, r2_ratio
        else:    
            return name, conc_rp, med_residual_rp, top_med_residual_rp, bottom_med_residual_rp, r2_rp
        
    else:
        print("{} is empty!".format(name))  
        if args.show_ransac_lin:
            return name, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan
        else:
            return name, np.nan, np.nan, np.nan, np.nan, np.nan
        
        
###### Run pipeline with parallel computing ######  
if __name__ == "__main__":
    if args.parallelisation:
        print("## start running pipeline with parallelisation ##")
        with multiprocessing.Pool() as p:
            results = list(tqdm(p.imap(build_pipeline, names), total=len(names)))
            p.close()
            df = pd.DataFrame(results)
            if args.show_ransac_lin:
                column_names = ["fundus", "conc_rp", "med_residual_rp", "top_med_residual_rp", "bottom_med_residual_rp", "r2_rp", "med_residual_lin", "r2_lin", "med_residual_ratio", "r2_ratio"]
            else:
                column_names = ["fundus", "conc_rp", "med_residual_rp", "top_med_residual_rp", "bottom_med_residual_rp", "r2_rp"]
            df = df.set_axis(column_names, axis=1)
            
            if os.path.normpath(args.vessel_path).split(os.sep)[-1] == "artery_binary_process":
                df.to_csv(join(homeDir, "CSVoutputs", "PREVENT", "arteryParabolaResults.csv"), index=False)
            else:
                df.to_csv(join(homeDir, "CSVoutputs", "PREVENT", "veinParabolaResults.csv"), index=False)
    
    else:
        matplotlib.use('TkAgg')
        if args.show_ransac_lin:
            fundus, conc_rp, med_residual_rp, top_med_residual_rp, bottom_med_residual_rp, r2_rp, med_residual_lin, r2_lin, med_residual_ratio, r2_ratio = build_pipeline(args.image_name)
        else:    
            fundus, conc_rp, med_residual_rp, top_med_residual_rp, bottom_med_residual_rp, r2_rp = build_pipeline(args.image_name)
        plt.show()
        
        
        
        
        
        